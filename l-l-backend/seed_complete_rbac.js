import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';

import departmentModel from './app/models/departmentModel.js';
import permissionGroupModel from './app/models/permissionGroupModel.js';
import roleModel from './app/models/roleModel.js';
import staffModel from './app/models/staffModel.js';
import { resolveRoleAndDepartment } from './app/services/staffService.js';
import { PERMISSION_REGISTRY } from './app/config/permissionRegistry.js';

const DEPARTMENTS_DATA = [
    {
        name: 'Sales',
        code: 'SALES',
        description: 'Lead generation, sales caller pools, relationship management, client follow-ups, and sales targets.',
        assignedPages: ['Leads', 'Users', 'Notifications'],
        isGlobal: false
    },
    {
        name: 'Research Analyst',
        code: 'RA',
        description: 'Market research, financial analysis, equity reports, trading calls, and publications.',
        assignedPages: ['Reports', 'Subscriptions'],
        isGlobal: false
    },
    {
        name: 'Operations & Compliance',
        code: 'OPS_COMP',
        description: 'KYC identity verification, operations tasks, payment receipts, bank transfers, and client compliance.',
        assignedPages: ['Users', 'KYC', 'Payments'],
        isGlobal: false
    },
    {
        name: 'Quality & Development',
        code: 'QUALITY_DEV',
        description: 'Quality audit, call verification, compliance checks, and operational standard reviews.',
        assignedPages: ['Reports', 'Leads', 'Users', 'KYC'],
        isGlobal: false
    },
    {
        name: 'HR',
        code: 'HR',
        description: 'Human resources, staff recruitment pipeline, employee management, and onboarding.',
        assignedPages: ['Staff'],
        isGlobal: false
    },
    {
        name: 'Back Office',
        code: 'BACKOFFICE',
        description: 'Back office administration, records processing, client documentation, and operational reporting.',
        assignedPages: ['Users', 'Payments', 'Subscriptions', 'Reports'],
        isGlobal: false
    },
    {
        name: 'Management',
        code: 'MANAGEMENT',
        description: 'Executive management, department oversight, organization-wide reporting, and administrative governance.',
        assignedPages: ['Leads', 'Users', 'Reports', 'Staff', 'KYC', 'Payments', 'Subscriptions', 'Notifications'],
        isGlobal: false
    },
    {
        name: 'Administration & Management',
        code: 'ADMIN',
        description: 'Complete cross-departmental access to all system features, security settings, and operations.',
        assignedPages: ['Leads', 'Users', 'Subscriptions', 'Payments', 'KYC', 'Reports', 'Staff', 'Notifications', 'Settings'],
        isGlobal: true
    }
];

export async function seedCompleteRBAC() {
    const mongoUri = process.env.DB_URL || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/researchvia-t';
    console.log(`Connecting to MongoDB for RBAC Seeding & Migration...`);
    if (mongoose.connection.readyState === 0) {
        await mongoose.connect(mongoUri);
    }

    console.log('--- STEP 1: UPSERT DEPARTMENTS ---');
    const deptMap = {}; // code -> dept document
    for (const d of DEPARTMENTS_DATA) {
        let dept = await departmentModel.findOne({
            $or: [
                { code: d.code },
                { name: { $regex: new RegExp(`^${d.name}$`, 'i') } }
            ]
        });

        // Check if legacy department matched
        if (!dept && d.code === 'RA') {
            dept = await departmentModel.findOne({ code: 'RESEARCH' });
        }
        if (!dept && d.code === 'OPS_COMP') {
            dept = await departmentModel.findOne({ code: 'OPERATIONS' });
        }
        if (!dept && d.code === 'SALES') {
            dept = await departmentModel.findOne({ name: 'Sales & Relationship Management' });
        }

        if (!dept) {
            dept = await departmentModel.create(d);
            console.log(`+ Created Department: ${d.name} (${d.code})`);
        } else {
            dept.name = d.name;
            dept.code = d.code;
            dept.description = d.description;
            dept.assignedPages = d.assignedPages;
            dept.isGlobal = d.isGlobal;
            dept.isActive = true;
            await dept.save();
            console.log(`~ Updated Department: ${d.name} (${d.code})`);
        }
        deptMap[d.code] = dept;
    }

    console.log('\n--- STEP 2: BUILD FULL ADMIN PERMISSION GROUP ---');
    const featureMap = {};
    Object.keys(PERMISSION_REGISTRY).forEach(key => {
        const item = PERMISSION_REGISTRY[key];
        if (!featureMap[item.feature]) {
            featureMap[item.feature] = [];
        }
        featureMap[item.feature].push(key);
    });
    const fullPermissions = Object.entries(featureMap).map(([feature, actions]) => ({
        feature,
        actions
    }));

    console.log('\n--- STEP 3: UPSERT PERMISSION GROUPS ---');
    const PERMISSION_GROUPS_DEF = [
        // SALES
        {
            name: 'SALES_BASIC',
            description: 'Basic sales views for reports and live trading call alerts',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Reports', actions: ['reports.view', 'reports.trading_call_popup'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.preview'] }
            ]
        },
        {
            name: 'SALES_LEAD_BASIC',
            description: 'Core lead operations: view assigned leads, create, follow-up, and pull fresh leads',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Leads', actions: ['leads.view', 'leads.create', 'leads.update', 'leads.follow_up', 'leads.pull'] },
                { feature: 'Users', actions: ['users.view'] }
            ]
        },
        {
            name: 'SALES_LEAD_ASSIGNMENT',
            description: 'Lead assignment and pool allocations to caller queues',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Leads', actions: ['leads.bulk_assign', 'leads.view_pools'] }
            ]
        },
        {
            name: 'SALES_LEAD_BULK_IMPORT',
            description: 'Import campaigns and bulk lead files into pools',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Leads', actions: ['leads.bulk_upload'] }
            ]
        },
        {
            name: 'SALES_TEAM_MANAGEMENT',
            description: 'Sales team overview and client reassignment to team staff',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Staff', actions: ['staff.view', 'staff.assignment'] }
            ]
        },
        {
            name: 'SALES_CLIENT_FINANCE_VIEW',
            description: 'Visibility into client plans and pending payments for sales tracking',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Subscriptions', actions: ['subscriptions.view'] },
                { feature: 'Payments', actions: ['payments.view_pending'] }
            ]
        },
        {
            name: 'SALES_RELATIONSHIP_MANAGEMENT',
            description: 'Create and update client relationship accounts and profiles',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Users', actions: ['users.create', 'users.update'] }
            ]
        },
        {
            name: 'SALES_REPORT_EXPORT',
            description: 'Export sales reports and financial payment reconciliation',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Payments', actions: ['payments.export'] }
            ]
        },
        {
            name: 'SALES_FLOOR_SUPERVISION',
            description: 'Floor management oversight, candidate verification, and pool monitoring',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Staff', actions: ['staff.view', 'staff.assignment', 'staff.view_applicants'] },
                { feature: 'Leads', actions: ['leads.view_pools'] }
            ]
        },
        {
            name: 'SALES_HEAD_MANAGEMENT',
            description: 'Sales department head administration, broadcasting, and email campaigns',
            deptCode: 'SALES',
            permissions: [
                { feature: 'Notifications', actions: ['notifications.send', 'notifications.send_bulk_email'] }
            ]
        },

        // RESEARCH ANALYST (RA)
        {
            name: 'RA_RESEARCH_BASIC',
            description: 'Basic research dashboard and live call preview',
            deptCode: 'RA',
            permissions: [
                { feature: 'Reports', actions: ['reports.view', 'reports.trading_call_popup'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.preview'] }
            ]
        },
        {
            name: 'RA_RESEARCH_CREATE',
            description: 'Draft and update equity research reports and trading calls',
            deptCode: 'RA',
            permissions: [
                { feature: 'Reports', actions: ['reports.create', 'reports.update'] }
            ]
        },
        {
            name: 'RA_RESEARCH_PUBLISH',
            description: 'Publish, unpublish, and delete research reports and dispatch trading call push notifications',
            deptCode: 'RA',
            permissions: [
                { feature: 'Reports', actions: ['reports.change_public_status', 'reports.delete'] },
                { feature: 'Notifications', actions: ['notifications.send'] }
            ]
        },

        // OPERATIONS & COMPLIANCE (OPS_COMP)
        {
            name: 'OPS_PAYMENTS_MANAGEMENT',
            description: 'Verification, approval, and management of bank transfers and subscription entitlements',
            deptCode: 'OPS_COMP',
            permissions: [
                { feature: 'Payments', actions: ['payments.view_pending', 'payments.approve', 'payments.reject', 'payments.export'] },
                { feature: 'Subscriptions', actions: ['subscriptions.view', 'subscriptions.activate', 'subscriptions.manage_segments', 'subscriptions.edit_correction'] },
                { feature: 'Users', actions: ['users.view', 'users.create', 'users.update'] }
            ]
        },
        {
            name: 'SUPPORT_TICKET_MANAGEMENT',
            description: 'Customer support, temp PIN generation, profile management, and ticket inquiries',
            deptCode: 'OPS_COMP',
            permissions: [
                { feature: 'Users', actions: ['users.view', 'users.update', 'users.generate_temp_pin'] },
                { feature: 'Subscriptions', actions: ['subscriptions.view'] },
                { feature: 'Payments', actions: ['payments.view_pending'] },
                { feature: 'Leads', actions: ['leads.view'] }
            ]
        },
        {
            name: 'COMPLIANCE_KYC_VERIFICATION',
            description: 'Client KYC verification, Digio/CVL KRA approvals, and regulatory compliance',
            deptCode: 'OPS_COMP',
            permissions: [
                { feature: 'KYC', actions: ['kyc.view', 'kyc.download_document', 'kyc.change_status', 'kyc.update_gate_status', 'kyc.update_file'] },
                { feature: 'Users', actions: ['users.view', 'users.suspend_activate'] }
            ]
        },
        {
            name: 'OPS_HEAD_SUPERVISION',
            description: 'Operations and compliance head supervision: plan suspensions, revokes, and alerts',
            deptCode: 'OPS_COMP',
            permissions: [
                { feature: 'Subscriptions', actions: ['subscriptions.suspend', 'subscriptions.revoke'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.send'] }
            ]
        },

        // QUALITY & DEVELOPMENT (QUALITY_DEV)
        {
            name: 'QUALITY_AUDIT_VIEW',
            description: 'Quality audit and inspection of reports, leads, clients, and KYC',
            deptCode: 'QUALITY_DEV',
            permissions: [
                { feature: 'Reports', actions: ['reports.view'] },
                { feature: 'Leads', actions: ['leads.view'] },
                { feature: 'Users', actions: ['users.view'] },
                { feature: 'KYC', actions: ['kyc.view'] }
            ]
        },
        {
            name: 'QUALITY_SUPERVISION',
            description: 'Senior quality oversight and quality team reviews',
            deptCode: 'QUALITY_DEV',
            permissions: [
                { feature: 'Staff', actions: ['staff.view'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.preview'] }
            ]
        },

        // HR
        {
            name: 'HR_RECRUITMENT',
            description: 'Recruitment queue, viewing applicant submissions, and approving candidate onboarding',
            deptCode: 'HR',
            permissions: [
                { feature: 'Staff', actions: ['staff.view', 'staff.view_applicants', 'staff.approve_applicant'] }
            ]
        },
        {
            name: 'HR_EMPLOYEE_MANAGEMENT',
            description: 'Staff directory management, creating staff profiles, editing details, and MPIN reset',
            deptCode: 'HR',
            permissions: [
                { feature: 'Staff', actions: ['staff.view', 'staff.create', 'staff.update', 'staff.reset_mpin'] }
            ]
        },
        {
            name: 'HR_ADMINISTRATION',
            description: 'HR Head authority to deactivate/delete staff and send internal notifications',
            deptCode: 'HR',
            permissions: [
                { feature: 'Staff', actions: ['staff.delete'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.send'] }
            ]
        },

        // BACK OFFICE
        {
            name: 'BACKOFFICE_PROCESSING',
            description: 'Back office client documentation, record processing, and payment slip review',
            deptCode: 'BACKOFFICE',
            permissions: [
                { feature: 'Users', actions: ['users.view', 'users.update'] },
                { feature: 'Payments', actions: ['payments.view_pending'] },
                { feature: 'Subscriptions', actions: ['subscriptions.view'] },
                { feature: 'Reports', actions: ['reports.view'] }
            ]
        },

        // MANAGEMENT
        {
            name: 'MANAGEMENT_ORGANIZATION_OVERVIEW',
            description: 'Comprehensive cross-departmental executive visibility and organizational oversight',
            deptCode: 'MANAGEMENT',
            permissions: [
                { feature: 'Leads', actions: ['leads.view', 'leads.pull', 'leads.follow_up', 'leads.view_pools'] },
                { feature: 'Users', actions: ['users.view', 'users.create', 'users.update', 'users.suspend_activate'] },
                { feature: 'Reports', actions: ['reports.view', 'reports.trading_call_popup'] },
                { feature: 'Staff', actions: ['staff.view', 'staff.update', 'staff.assignment', 'staff.view_applicants'] },
                { feature: 'KYC', actions: ['kyc.view', 'kyc.update_gate_status'] },
                { feature: 'Payments', actions: ['payments.view_pending', 'payments.export'] },
                { feature: 'Subscriptions', actions: ['subscriptions.view'] },
                { feature: 'Notifications', actions: ['notifications.view', 'notifications.preview'] }
            ]
        },

        // ADMIN
        {
            name: 'admin',
            description: 'Default Admin Group with all canonical permissions',
            deptCode: 'ADMIN',
            permissions: fullPermissions
        }
    ];

    const groupMap = {}; // name -> permissionGroup document
    for (const gDef of PERMISSION_GROUPS_DEF) {
        const dept = deptMap[gDef.deptCode];
        let group = await permissionGroupModel.findOne({ name: gDef.name });
        if (!group) {
            group = await permissionGroupModel.create({
                name: gDef.name,
                description: gDef.description,
                departmentId: dept ? dept._id : null,
                permissions: gDef.permissions
            });
            console.log(`+ Created Permission Group: ${gDef.name} (${gDef.deptCode})`);
        } else {
            group.description = gDef.description;
            group.departmentId = dept ? dept._id : group.departmentId;
            group.permissions = gDef.permissions;
            await group.save();
            console.log(`~ Updated Permission Group: ${gDef.name} (${gDef.deptCode})`);
        }
        groupMap[gDef.name] = group;
    }

    console.log('\n--- STEP 4: UPSERT ALL 28+ ROLES ---');
    const ROLES_DEF = [
        // 1. Sales Roles
        {
            name: 'Business Development Executive',
            code: 'BDE',
            level: 1,
            deptCode: 'SALES',
            description: 'Entry-level sales executive handling assigned lead generation and direct follow-ups.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC']
        },
        {
            name: 'Senior Business Development Executive',
            code: 'SBDE',
            level: 2,
            deptCode: 'SALES',
            description: 'Experienced sales executive with client financial visibility and performance tracking.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW']
        },
        {
            name: 'Team Leader',
            code: 'TL',
            level: 3,
            deptCode: 'SALES',
            description: 'Sales team leader managing caller distribution, pooling, and team assignments.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_LEAD_ASSIGNMENT', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_TEAM_MANAGEMENT']
        },
        {
            name: 'Project Team Leader',
            code: 'PTL',
            level: 4,
            deptCode: 'SALES',
            description: 'Project team leader coordinating campaign leads and target tracking.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_BULK_IMPORT']
        },
        {
            name: 'Senior Team Leader',
            code: 'STL',
            level: 5,
            deptCode: 'SALES',
            description: 'Senior team leader supervising multiple caller groups, team allocations, and lead export.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_BULK_IMPORT', 'SALES_REPORT_EXPORT']
        },
        {
            name: 'Relationship Manager',
            code: 'RM',
            level: 6,
            deptCode: 'SALES',
            description: 'Relationship manager managing client accounts, profile onboarding, and client portfolios.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_RELATIONSHIP_MANAGEMENT', 'SALES_TEAM_MANAGEMENT']
        },
        {
            name: 'Assistant Relationship Manager',
            code: 'ARM',
            level: 7,
            deptCode: 'SALES',
            description: 'Assisting relationship manager supporting client portfolio, conversions, and lead queue allocations.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_RELATIONSHIP_MANAGEMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_ASSIGNMENT']
        },
        {
            name: 'Senior Relationship Manager',
            code: 'SRM',
            level: 8,
            deptCode: 'SALES',
            description: 'Senior relationship manager overseeing strategic key accounts and sales operations with export.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_RELATIONSHIP_MANAGEMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_ASSIGNMENT', 'SALES_REPORT_EXPORT']
        },
        {
            name: 'Floor Manager',
            code: 'FM',
            level: 9,
            deptCode: 'SALES',
            description: 'Floor manager directing daily sales trading floor callers, queues, and shifts.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_FLOOR_SUPERVISION']
        },
        {
            name: 'Assistant Floor Manager',
            code: 'AFM',
            level: 10,
            deptCode: 'SALES',
            description: 'Assistant floor manager supervising caller floor operations and client profiles.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_FLOOR_SUPERVISION', 'SALES_RELATIONSHIP_MANAGEMENT']
        },
        {
            name: 'Senior Floor Manager',
            code: 'SFM',
            level: 11,
            deptCode: 'SALES',
            description: 'Senior floor manager overseeing full operational floor performance, bulk imports, and reconciliation.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_BULK_IMPORT', 'SALES_FLOOR_SUPERVISION', 'SALES_RELATIONSHIP_MANAGEMENT', 'SALES_REPORT_EXPORT']
        },
        {
            name: 'Sales Head',
            code: 'SH',
            level: 12,
            deptCode: 'SALES',
            description: 'Executive Sales Head with complete sales management and broadcasting permissions.',
            groups: ['SALES_BASIC', 'SALES_LEAD_BASIC', 'SALES_CLIENT_FINANCE_VIEW', 'SALES_LEAD_ASSIGNMENT', 'SALES_TEAM_MANAGEMENT', 'SALES_LEAD_BULK_IMPORT', 'SALES_FLOOR_SUPERVISION', 'SALES_RELATIONSHIP_MANAGEMENT', 'SALES_REPORT_EXPORT', 'SALES_HEAD_MANAGEMENT']
        },

        // 2. Research Analyst (RA) Roles
        {
            name: 'Junior Research Analyst',
            code: 'JRA',
            level: 1,
            deptCode: 'RA',
            description: 'Entry-level research analyst creating drafts of research reports and trading ideas.',
            groups: ['RA_RESEARCH_BASIC', 'RA_RESEARCH_CREATE']
        },
        {
            name: 'Senior Research Analyst',
            code: 'SRA',
            level: 2,
            deptCode: 'RA',
            description: 'Senior analyst drafting, updating, reviewing, and publishing research calls.',
            groups: ['RA_RESEARCH_BASIC', 'RA_RESEARCH_CREATE', 'RA_RESEARCH_PUBLISH']
        },
        {
            name: 'Research Analyst',
            code: 'RA',
            level: 3,
            deptCode: 'RA',
            description: 'Licensed Research Analyst with publishing and advisory dispatch authority.',
            groups: ['RA_RESEARCH_BASIC', 'RA_RESEARCH_CREATE', 'RA_RESEARCH_PUBLISH']
        },

        // 3. Operations & Compliance Roles
        {
            name: 'Operations Executive',
            code: 'OP_EXECUTIVE',
            level: 1,
            deptCode: 'OPS_COMP',
            description: 'Operations executive managing bank transfers, payment verification, and plan activations.',
            groups: ['OPS_PAYMENTS_MANAGEMENT']
        },
        {
            name: 'Operations Head',
            code: 'OP_HEAD',
            level: 2,
            deptCode: 'OPS_COMP',
            description: 'Head of operations with payment approval, plan suspension, and supervision authority.',
            groups: ['OPS_PAYMENTS_MANAGEMENT', 'OPS_HEAD_SUPERVISION']
        },
        {
            name: 'Support Executive',
            code: 'SUPPORT_EXECUTIVE',
            level: 1,
            deptCode: 'OPS_COMP',
            description: 'Support executive handling customer support inquiries, temp PINs, and client assistance.',
            groups: ['SUPPORT_TICKET_MANAGEMENT']
        },
        {
            name: 'Support Head',
            code: 'SUPPORT_HEAD',
            level: 2,
            deptCode: 'OPS_COMP',
            description: 'Support supervisor overseeing customer escalation and operations notifications.',
            groups: ['SUPPORT_TICKET_MANAGEMENT', 'OPS_HEAD_SUPERVISION']
        },
        {
            name: 'Compliance Executive',
            code: 'COMPLIANCE_EXECUTIVE',
            level: 1,
            deptCode: 'OPS_COMP',
            description: 'Compliance executive executing KYC verification and identity checks.',
            groups: ['COMPLIANCE_KYC_VERIFICATION']
        },
        {
            name: 'Compliance Head',
            code: 'COMPLIANCE_HEAD',
            level: 2,
            deptCode: 'OPS_COMP',
            description: 'Compliance head supervising regulatory compliance and gate audits.',
            groups: ['COMPLIANCE_KYC_VERIFICATION', 'OPS_HEAD_SUPERVISION']
        },

        // 4. Quality & Development Roles
        {
            name: 'Quality Check',
            code: 'QUALITY_CHECK',
            level: 1,
            deptCode: 'QUALITY_DEV',
            description: 'Quality executive reviewing calls, reports, and client interaction compliance.',
            groups: ['QUALITY_AUDIT_VIEW']
        },
        {
            name: 'Senior Quality Check',
            code: 'SENIOR_Q_CHECK',
            level: 2,
            deptCode: 'QUALITY_DEV',
            description: 'Senior quality auditor monitoring department adherence to standards.',
            groups: ['QUALITY_AUDIT_VIEW', 'QUALITY_SUPERVISION']
        },
        {
            name: 'Head of Department (Quality)',
            code: 'HOD_QUALITY',
            level: 3,
            deptCode: 'QUALITY_DEV',
            description: 'Head of Quality & Development ensuring overall compliance and operational quality.',
            groups: ['QUALITY_AUDIT_VIEW', 'QUALITY_SUPERVISION']
        },

        // 5. HR Roles
        {
            name: 'Human Resources',
            code: 'HR',
            level: 1,
            deptCode: 'HR',
            description: 'HR executive managing staff employee records, directory, and MPIN credentials.',
            groups: ['HR_EMPLOYEE_MANAGEMENT']
        },
        {
            name: 'Recruitment HR',
            code: 'RECRUITMENT_HR',
            level: 1,
            deptCode: 'HR',
            description: 'Recruiter handling job applicant screening and onboarding applicant approvals.',
            groups: ['HR_RECRUITMENT']
        },
        {
            name: 'Senior Human Resources',
            code: 'SHR',
            level: 2,
            deptCode: 'HR',
            description: 'Senior HR specialist managing employee lifecycle and recruitment.',
            groups: ['HR_EMPLOYEE_MANAGEMENT', 'HR_RECRUITMENT']
        },
        {
            name: 'Head of Department (HR)',
            code: 'HOD_HR',
            level: 3,
            deptCode: 'HR',
            description: 'Head of HR with complete staff lifecycle, onboarding, and deactivation permissions.',
            groups: ['HR_EMPLOYEE_MANAGEMENT', 'HR_RECRUITMENT', 'HR_ADMINISTRATION']
        },

        // 6. Back Office Roles
        {
            name: 'Back Office Executive',
            code: 'BACKOFFICE_EXECUTIVE',
            level: 1,
            deptCode: 'BACKOFFICE',
            description: 'Back office executive handling client records, payment slips, and reporting data.',
            groups: ['BACKOFFICE_PROCESSING']
        },

        // 7. Management Roles
        {
            name: 'Director',
            code: 'DIRECTOR',
            level: 1,
            deptCode: 'MANAGEMENT',
            description: 'Company Director with broad organizational visibility and operational oversight.',
            groups: ['MANAGEMENT_ORGANIZATION_OVERVIEW']
        },

        // 8. Admin Role
        {
            name: 'Admin',
            code: 'ADMIN',
            level: 100,
            deptCode: 'ADMIN',
            description: 'System Administrator with full access across all platform capabilities.',
            groups: ['admin']
        }
    ];

    const roleMap = {}; // code -> role document
    for (const rDef of ROLES_DEF) {
        const dept = deptMap[rDef.deptCode];
        const permissionGroupIds = (rDef.groups || [])
            .map(gName => groupMap[gName]?._id)
            .filter(Boolean);

        // Find by code, or by name
        let role = await roleModel.findOne({
            $or: [
                { code: rDef.code },
                { name: { $regex: new RegExp(`^${rDef.name}$`, 'i') } }
            ]
        });

        // Also check if legacy role exists
        if (!role && rDef.code === 'DIRECTOR') {
            role = await roleModel.findOne({ name: 'Directors' });
        }
        if (!role && rDef.code === 'RA') {
            role = await roleModel.findOne({ name: 'Researcher' });
        }
        if (!role && rDef.code === 'JRA') {
            role = await roleModel.findOne({ name: 'Jr Research Analyst' });
        }

        if (!role) {
            role = await roleModel.create({
                name: rDef.name,
                code: rDef.code,
                level: rDef.level,
                description: rDef.description,
                departmentId: dept ? dept._id : null,
                permissionGroups: permissionGroupIds,
                isActive: true
            });
            console.log(`+ Created Role: ${rDef.name} [${rDef.code}] (Level ${rDef.level}, Dept: ${rDef.deptCode})`);
        } else {
            role.name = rDef.name;
            role.code = rDef.code;
            role.level = rDef.level;
            role.description = rDef.description;
            role.departmentId = dept ? dept._id : role.departmentId;
            role.permissionGroups = permissionGroupIds;
            role.isActive = true;
            await role.save();
            console.log(`~ Updated Role: ${rDef.name} [${rDef.code}] (Level ${rDef.level}, Dept: ${rDef.deptCode})`);
        }
        roleMap[rDef.code] = role;
    }

    console.log('\n--- STEP 5: MIGRATE & SYNCHRONIZE EXISTING STAFF ---');
    const allStaff = await staffModel.find();
    console.log(`Found ${allStaff.length} staff members to evaluate and synchronize.`);

    let updatedCount = 0;
    for (const s of allStaff) {
        const currentRoleStr = (s.role || "").toLowerCase();
        const currentDeptStr = (s.deparment || s.department || "").toLowerCase();

        let assignedRole = null;

        // If staff already has a valid roleId pointing to an existing role
        if (s.roleId) {
            assignedRole = await roleModel.findById(s.roleId);
        }

        // If no roleId or roleId was not found, infer from current role / department strings
        if (!assignedRole) {
            if (currentRoleStr.includes('director') || currentDeptStr.includes('director')) {
                assignedRole = roleMap['DIRECTOR'];
            } else if (currentRoleStr.includes('admin') || currentDeptStr.includes('admin')) {
                assignedRole = roleMap['ADMIN'];
            } else if (currentRoleStr.includes('junior') || currentDeptStr.includes('junior')) {
                assignedRole = roleMap['JRA'];
            } else if (currentRoleStr.includes('research') || currentDeptStr.includes('research')) {
                assignedRole = roleMap['RA'];
            } else if (currentRoleStr.includes('manager') || currentDeptStr.includes('manager')) {
                assignedRole = roleMap['FM']; // Floor Manager
            } else if (currentRoleStr.includes('compliance') || currentDeptStr.includes('compliance')) {
                assignedRole = roleMap['COMPLIANCE_EXECUTIVE'];
            } else if (currentRoleStr.includes('hr') || currentDeptStr.includes('hr')) {
                assignedRole = roleMap['HR'];
            } else {
                // Default fallback to Business Development Executive (BDE)
                assignedRole = roleMap['BDE'];
            }
        }

        if (assignedRole) {
            // Automatically derive department from role
            const resolved = await resolveRoleAndDepartment({ roleId: assignedRole._id });
            s.roleId = assignedRole._id;
            s.role = assignedRole.name;
            s.departmentId = resolved.departmentId;
            s.deparment = resolved.departmentName;
            await s.save();
            updatedCount++;
            console.log(`✓ Staff "${s.fullName}" (${s.email || s.mobile}) -> Assigned Role: ${assignedRole.name} [${assignedRole.code}], Derived Dept: ${resolved.departmentName}`);
        }
    }

    console.log(`\n======================================================`);
    console.log(`Seeding & Migration Complete! Synchronized ${updatedCount} staff records.`);
    console.log(`Total Departments: ${Object.keys(deptMap).length}`);
    console.log(`Total Permission Groups: ${Object.keys(groupMap).length}`);
    console.log(`Total Roles: ${Object.keys(roleMap).length}`);
    console.log(`======================================================\n`);
}

// Allow direct execution via CLI
if (process.argv[1] && process.argv[1].endsWith('seed_complete_rbac.js')) {
    seedCompleteRBAC()
        .then(() => {
            console.log('RBAC Seeding script completed successfully.');
            process.exit(0);
        })
        .catch(err => {
            console.error('Fatal error during RBAC seeding:', err);
            process.exit(1);
        });
}
