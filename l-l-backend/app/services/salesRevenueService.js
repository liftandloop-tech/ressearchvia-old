import mongoose from 'mongoose';
import paymentIntentModel from '../models/paymentIntentModel.js';
import userModel from '../models/userModel.js';
import staffModel from '../models/staffModel.js';
import staffAssignmentModel from '../models/staffAssignmentModel.js';
import segmentsPlansModel from '../models/segmentsPlansModel.js';
import { getSupervisedStaffIds } from '../utils/staffHierarchy.js';

export const salesRevenueService = {
  /**
   * Unified calculation for Realized Sales Revenue & GST breakdown.
   * Can be scoped by caller (RBAC hierarchy), date range, department, staff, search, and status.
   */
  computeRealizedMetrics: async ({
    callerId,
    startDate,
    endDate,
    department,
    staffMember,
    staffId,
    search,
    status
  } = {}) => {
    let isSystemAdmin = false;
    let targetStaffIds = [];

    if (callerId) {
      const hierarchy = await getSupervisedStaffIds(callerId);
      isSystemAdmin = hierarchy.isSystemAdmin;
      if (!isSystemAdmin) {
        targetStaffIds = hierarchy.staffIds || [new mongoose.Types.ObjectId(callerId)];
      }
    } else {
      isSystemAdmin = true;
    }

    // 1. Fetch Staff List & Department Hierarchy
    const staffListQuery = (!isSystemAdmin && targetStaffIds.length > 0)
      ? { _id: { $in: targetStaffIds } }
      : {};
    const staffList = await staffModel.find(staffListQuery).select('fullName staffId deparment emailAddress mobileNumber status');

    const staffDeptMap = {};
    staffList.forEach(s => {
      staffDeptMap[s._id.toString()] = s.deparment || 'Sales';
    });

    // 2. Fetch User-to-Staff Assignments
    const assignmentQuery = (!isSystemAdmin && targetStaffIds.length > 0)
      ? { staffId: { $in: targetStaffIds } }
      : {};
    const allAssignments = await staffAssignmentModel.find(assignmentQuery);

    const userToStaffMap = {};
    const staffClientCountMap = {};
    allAssignments.forEach(ass => {
      if (ass.userId && ass.staffId) {
        const uId = ass.userId.toString();
        const sId = ass.staffId.toString();
        const dept = staffDeptMap[sId] || 'Sales';
        userToStaffMap[uId] = { staffId: ass.staffId, staffName: ass.staffName, department: dept };
        staffClientCountMap[sId] = (staffClientCountMap[sId] || 0) + 1;
      }
    });

    // 3. Filter Staff by department / staffMember / staffId if requested
    let filteredStaffList = staffList;
    if (department && department !== 'All Departments' && department !== 'All') {
      const d = department.trim().toLowerCase();
      filteredStaffList = filteredStaffList.filter(s => (s.deparment || '').toLowerCase() === d);
    }
    if (staffMember && staffMember !== 'All Staff' && staffMember !== 'All Managers') {
      const sm = staffMember.trim().toLowerCase();
      filteredStaffList = filteredStaffList.filter(s => (s.fullName || '').toLowerCase() === sm);
    }
    if (staffId) {
      const sid = staffId.toString();
      filteredStaffList = filteredStaffList.filter(s => s._id.toString() === sid || s.staffId === sid);
    }
    const allowedStaffIdSet = new Set(filteredStaffList.map(s => s._id.toString()));

    // 4. Build PaymentIntent Query
    const queryArgs = {
      $or: [
        { proofImage: { $ne: null, $exists: true } },
        { 'proofImages.0': { $exists: true } },
        { 'partialPaymentsHistory.0': { $exists: true } },
        { purchaseType: 'REGISTRATION' },
        { paymentMethod: 'BANK_TRANSFER' },
        { status: { $in: ['PAID', 'APPROVED', 'SUCCESS', 'PARTIAL-PAID'] } }
      ]
    };

    // RBAC: Non-admin can only see payments for assigned users
    if (!isSystemAdmin && targetStaffIds.length > 0) {
      const assignedUserIds = allAssignments.map(a => a.userId).filter(Boolean);
      queryArgs.userId = { $in: assignedUserIds };
    }

    // Date filtering bounds
    let filterStart = startDate ? new Date(startDate) : null;
    let filterEnd = endDate ? new Date(endDate) : null;
    if (filterStart) filterStart.setHours(0, 0, 0, 0);
    if (filterEnd) filterEnd.setHours(23, 59, 59, 999);

    // 5. Query Payments
    const intents = await paymentIntentModel.find(queryArgs)
      .populate({
        path: 'userId',
        model: userModel,
        select: 'fullName phone email gstin firmName panNumber state userObject'
      })
      .populate({
        path: 'planId',
        model: segmentsPlansModel,
        select: 'planName price duration'
      })
      .sort({ createdAt: -1 });

    // 6. Aggregate Realized Revenue & GST breakdown
    let grossTurnover = 0.0;
    let taxableTurnover = 0.0;
    let totalTax = 0.0;
    let cgst = 0.0;
    let sgst = 0.0;
    let igst = 0.0;
    let b2bCount = 0;
    let b2cCount = 0;
    let b2bAmount = 0.0;
    let b2cAmount = 0.0;

    const staffSalesMap = {};
    let realizedOrders = [];

    for (const intent of intents) {
      const user = intent.userId || {};
      const uId = user._id ? user._id.toString() : (intent.userId ? intent.userId.toString() : null);
      const staffInfo = uId ? userToStaffMap[uId] : null;
      const staffName = staffInfo?.staffName || 'Unassigned';
      const sId = staffInfo?.staffId ? staffInfo.staffId.toString() : null;
      const staffDept = staffInfo?.department || (sId && staffDeptMap[sId] ? staffDeptMap[sId] : 'Sales');

      // Staff filter check
      if ((department && department !== 'All Departments' && department !== 'All') ||
          (staffMember && staffMember !== 'All Staff' && staffMember !== 'All Managers') ||
          staffId) {
        if (!sId || !allowedStaffIdSet.has(sId)) {
          continue;
        }
      }

      // State & GST resolution
      const gstin = (user.gstin || intent.gstin || '').toString().trim().toUpperCase();
      const isB2b = gstin.length === 15;
      const stateStr = (user.state || user.userObject?.state || '').toString().trim().toLowerCase();
      const stateCodeFromGstin = isB2b ? gstin.slice(0, 2) : '';
      const isIntraState = stateCodeFromGstin === '23' || stateStr.includes('madhya') || stateStr === 'mp';

      const parentDate = intent.createdAt ? new Date(intent.createdAt) : new Date();
      const history = intent.partialPaymentsHistory || [];
      let hasCalculatedInstallment = false;

      // Case A: Partial Payments History (Installments)
      if (history.length > 0) {
        for (const item of history) {
          const hStatus = (item.status || '').toUpperCase();
          if (hStatus !== 'APPROVED') continue;

          const instAmount = Number(item.amountPaid || 0);
          if (instAmount <= 0) continue;

          // Transaction date prioritized
          const instDate = item.transactionDate
            ? new Date(item.transactionDate)
            : (item.verifiedAt ? new Date(item.verifiedAt) : parentDate);

          if (filterStart && instDate < filterStart) continue;
          if (filterEnd && instDate > filterEnd) continue;

          hasCalculatedInstallment = true;
          grossTurnover += instAmount;
          const base = instAmount / 1.18;
          const tax = instAmount - base;
          taxableTurnover += base;
          totalTax += tax;

          if (isB2b) {
            b2bCount++;
            b2bAmount += instAmount;
          } else {
            b2cCount++;
            b2cAmount += instAmount;
          }

          if (isIntraState) {
            cgst += (tax / 2);
            sgst += (tax / 2);
          } else {
            igst += tax;
          }

          const orderId = `ORD-${(intent._id.toString()).slice(-6).toUpperCase()}-${(item._id ? item._id.toString().slice(-4).toUpperCase() : 'INST')}`;
          const clientName = user.fullName || (user.userObject?.firstName ? `${user.userObject.firstName} ${user.userObject.lastName || ''}`.trim() : 'Customer');
          const packageName = intent.purchaseType === 'REGISTRATION' ? 'Registration Fee' : (intent.planId?.planName || 'Subscription Plan');

          realizedOrders.push({
            id: `${intent._id}_${item._id || Math.random()}`,
            orderId,
            clientName,
            clientPhone: user.phone || user.userObject?.mobileNumber || '-',
            clientEmail: user.email || user.userObject?.emailAddress || '-',
            packageName: `${packageName} (Installment)`,
            amount: instAmount,
            status: 'paid',
            isPartial: true,
            isPaid: true,
            staffId: sId,
            staffName,
            department: staffDept,
            createdAt: instDate.toISOString(),
          });

          if (sId) {
            staffSalesMap[sId] = staffSalesMap[sId] || { ordersCount: 0, paidOrdersCount: 0, totalAmount: 0 };
            staffSalesMap[sId].paidOrdersCount++;
            staffSalesMap[sId].ordersCount++;
            staffSalesMap[sId].totalAmount += instAmount;
          }
        }
      }

      // Case B: Direct Realized Payment (No installment history)
      if (!hasCalculatedInstallment && history.length === 0) {
        const s = (intent.status || '').toUpperCase();
        if (['PAID', 'APPROVED', 'PARTIAL-PAID', 'SUCCESS'].includes(s)) {
          const paid = Number(intent.amountPaid || (s === 'PAID' ? intent.totalAmount : 0) || 0);
          if (paid > 0) {
            const paymentDate = intent.transactionDate ? new Date(intent.transactionDate) : parentDate;
            if (filterStart && paymentDate < filterStart) continue;
            if (filterEnd && paymentDate > filterEnd) continue;

            grossTurnover += paid;
            const base = paid / 1.18;
            const tax = paid - base;
            taxableTurnover += base;
            totalTax += tax;

            if (isB2b) {
              b2bCount++;
              b2bAmount += paid;
            } else {
              b2cCount++;
              b2cAmount += paid;
            }

            if (isIntraState) {
              cgst += (tax / 2);
              sgst += (tax / 2);
            } else {
              igst += tax;
            }

            const orderId = `ORD-${(intent._id.toString()).slice(-6).toUpperCase()}`;
            const clientName = user.fullName || (user.userObject?.firstName ? `${user.userObject.firstName} ${user.userObject.lastName || ''}`.trim() : 'Customer');
            const packageName = intent.purchaseType === 'REGISTRATION' ? 'Registration Fee' : (intent.planId?.planName || 'Subscription Plan');

            realizedOrders.push({
              id: intent._id.toString(),
              orderId,
              clientName,
              clientPhone: user.phone || user.userObject?.mobileNumber || '-',
              clientEmail: user.email || user.userObject?.emailAddress || '-',
              packageName,
              amount: paid,
              status: 'paid',
              isPartial: false,
              isPaid: true,
              staffId: sId,
              staffName,
              department: staffDept,
              createdAt: paymentDate.toISOString(),
            });

            if (sId) {
              staffSalesMap[sId] = staffSalesMap[sId] || { ordersCount: 0, paidOrdersCount: 0, totalAmount: 0 };
              staffSalesMap[sId].paidOrdersCount++;
              staffSalesMap[sId].ordersCount++;
              staffSalesMap[sId].totalAmount += paid;
            }
          }
        }
      }
    }

    // Filter realized orders by search query if active
    if (search && search.trim().length > 0) {
      const q = search.trim().toLowerCase();
      realizedOrders = realizedOrders.filter(o => {
        return (
          (o.clientName && o.clientName.toLowerCase().includes(q)) ||
          (o.clientPhone && o.clientPhone.toLowerCase().includes(q)) ||
          (o.clientEmail && o.clientEmail.toLowerCase().includes(q)) ||
          (o.packageName && o.packageName.toLowerCase().includes(q)) ||
          (o.staffName && o.staffName.toLowerCase().includes(q)) ||
          (o.orderId && o.orderId.toLowerCase().includes(q))
        );
      });
    }

    // Sort orders descending by createdAt
    realizedOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const totalOrders = realizedOrders.length;
    const roundedGross = Math.round(grossTurnover);

    // Build Staff Performance List
    let staffPerformanceList = filteredStaffList.map(s => {
      const sId = s._id.toString();
      const salesData = staffSalesMap[sId] || { ordersCount: 0, paidOrdersCount: 0, totalAmount: 0 };
      return {
        id: sId,
        staffId: s.staffId || sId.slice(-6),
        name: s.fullName || 'Staff Member',
        department: s.deparment || 'Sales',
        email: s.emailAddress || '-',
        phone: s.mobileNumber || '-',
        assignedClients: staffClientCountMap[sId] || 0,
        ordersCount: salesData.paidOrdersCount || salesData.ordersCount,
        totalSalesAmount: Math.round(salesData.totalAmount),
      };
    });

    if (search && search.trim().length > 0) {
      const q = search.trim().toLowerCase();
      staffPerformanceList = staffPerformanceList.filter(s => {
        return (
          (s.name && s.name.toLowerCase().includes(q)) ||
          (s.email && s.email.toLowerCase().includes(q)) ||
          (s.department && s.department.toLowerCase().includes(q)) ||
          (s.staffId && s.staffId.toLowerCase().includes(q))
        );
      });
    }

    staffPerformanceList.sort((a, b) => b.totalSalesAmount - a.totalSalesAmount);

    const activeStaffCount = staffPerformanceList.filter(s => s.totalSalesAmount > 0 || s.assignedClients > 0).length;
    const avgOrderValue = totalOrders > 0 ? Math.round(roundedGross / totalOrders) : 0;

    // Department Sales Breakdown
    const departmentSalesMap = {};
    staffPerformanceList.forEach(s => {
      const dept = s.department || 'Sales';
      departmentSalesMap[dept] = (departmentSalesMap[dept] || 0) + s.totalSalesAmount;
    });

    const departmentSales = Object.keys(departmentSalesMap).map(dept => ({
      department: dept,
      totalSalesAmount: departmentSalesMap[dept],
    }));

    // Conversion rate
    const totalAssignedClients = staffPerformanceList.reduce((acc, s) => acc + s.assignedClients, 0);
    const conversionRate = totalAssignedClients > 0
      ? Math.round((totalOrders / totalAssignedClients) * 100)
      : (totalOrders > 0 ? 100 : 0);

    const topPerformingStaff = staffPerformanceList.length > 0 && staffPerformanceList[0].totalSalesAmount > 0
      ? staffPerformanceList[0]
      : (staffPerformanceList.length > 0 ? staffPerformanceList[0] : null);

    return {
      grossTurnover: roundedGross,
      totalSalesAmount: roundedGross,
      taxableTurnover: Math.round(taxableTurnover),
      totalTax: Math.round(totalTax),
      cgst: Math.round(cgst),
      sgst: Math.round(sgst),
      igst: Math.round(igst),
      b2bCount,
      b2cCount,
      b2bAmount: Math.round(b2bAmount),
      b2cAmount: Math.round(b2cAmount),
      totalOrders,
      activeStaffCount,
      avgOrderValue,
      conversionRate,
      topPerformingStaff,
      departmentSales,
      staffPerformanceList,
      ordersList: realizedOrders,
    };
  }
};

export default salesRevenueService;
