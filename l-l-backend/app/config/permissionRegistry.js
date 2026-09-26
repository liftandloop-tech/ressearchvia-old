export const PERMISSION_REGISTRY = {
    // Module 1: Leads & CRM
    'leads.view': { feature: 'Leads', action: 'view', label: 'View Leads', description: 'List and view sales leads' },
    'leads.create': { feature: 'Leads', action: 'create', label: 'Create Lead', description: 'Add new lead manually' },
    'leads.update': { feature: 'Leads', action: 'update', label: 'Edit Lead', description: 'Edit lead profile details' },
    'leads.follow_up': { feature: 'Leads', action: 'follow_up', label: 'Log Follow-up', description: 'Record follow-up calls and notes' },
    'leads.bulk_upload': { feature: 'Leads', action: 'bulk_upload', label: 'Bulk Upload Leads', description: 'Import leads from CSV/Excel' },
    'leads.bulk_assign': { feature: 'Leads', action: 'bulk_assign', label: 'Bulk Assign Leads', description: 'Assign multiple leads to RM' },
    'leads.pull': { feature: 'Leads', action: 'pull', label: 'Pull Fresh Leads', description: 'Pull fresh leads from lead pool' },
    'leads.view_pools': { feature: 'Leads', action: 'view_pools', label: 'Manage Lead Pools', description: 'View and create lead distribution pools' },

    // Module 2: Users & Clients
    'users.view': { feature: 'Users', action: 'view', label: 'View Clients', description: 'View client list and client profiles' },
    'users.create': { feature: 'Users', action: 'create', label: 'Create Client', description: 'Provision new client account' },
    'users.update': { feature: 'Users', action: 'update', label: 'Edit Client Profile', description: 'Edit client personal and bank details' },
    'users.suspend_activate': { feature: 'Users', action: 'suspend_activate', label: 'Suspend / Activate Client', description: 'Suspend or activate user account access' },
    'users.generate_temp_pin': { feature: 'Users', action: 'generate_temp_pin', label: 'Generate Temp PIN', description: 'Generate temporary login PIN for client' },
    'users.delete': { feature: 'Users', action: 'delete', label: 'Delete Client', description: 'Permanently delete client account' },

    // Module 3: Subscriptions & Entitlements
    'subscriptions.view': { feature: 'Subscriptions', action: 'view', label: 'View Subscriptions', description: 'View subscription history and active plans' },
    'subscriptions.activate': { feature: 'Subscriptions', action: 'activate', label: 'Activate / Top-Up Plan', description: 'Activate plans and add top-up amounts' },
    'subscriptions.suspend': { feature: 'Subscriptions', action: 'suspend', label: 'Suspend Subscription', description: 'Suspend active client subscription' },
    'subscriptions.revoke': { feature: 'Subscriptions', action: 'revoke', label: 'Revoke Subscription', description: 'Revoke client active subscription' },
    'subscriptions.manage_segments': { feature: 'Subscriptions', action: 'manage_segments', label: 'Manage Segments', description: 'Customize segments for client plan' },
    'subscriptions.edit_correction': { feature: 'Subscriptions', action: 'edit_correction', label: 'Edit Plan / Dates / Amount', description: 'Correct subscription plan, dates, or price' },
    'subscriptions.refund': { feature: 'Subscriptions', action: 'refund', label: 'Process Refund', description: 'Calculate and issue subscription refund' },

    // Module 4: Payments & Bank Transfers
    'payments.view_pending': { feature: 'Payments', action: 'view_pending', label: 'View Payments & Receipts', description: 'View pending bank transfers queue and payment receipts' },
    'payments.approve': { feature: 'Payments', action: 'approve', label: 'Approve Payment', description: 'Approve bank transfer payment' },
    'payments.reject': { feature: 'Payments', action: 'reject', label: 'Reject Payment', description: 'Reject pending bank transfer payment' },
    'payments.export': { feature: 'Payments', action: 'export', label: 'Export Payment Records', description: 'Export payment records to Excel' },

    // Module 5: KYC Verification
    'kyc.view': { feature: 'KYC', action: 'view', label: 'View KYC Submissions', description: 'View client KYC verification documents' },
    'kyc.download_document': { feature: 'KYC', action: 'download_document', label: 'Download KYC Documents', description: 'Download client PAN / Aadhaar documents' },
    'kyc.change_status': { feature: 'KYC', action: 'change_status', label: 'Approve / Reject KYC', description: 'Approve or reject client KYC submission' },
    'kyc.update_gate_status': { feature: 'KYC', action: 'update_gate_status', label: 'Update Gate Status', description: 'Change verification gate status' },
    'kyc.update_file': { feature: 'KYC', action: 'update_file', label: 'Update KYC File', description: 'Re-upload or replace KYC file' },

    // Module 6: Reports & Advisory
    'reports.view': { feature: 'Reports', action: 'view', label: 'View Research Reports', description: 'Browse published and draft reports' },
    'reports.create': { feature: 'Reports', action: 'create', label: 'Upload Research Report', description: 'Upload and create new research report' },
    'reports.update': { feature: 'Reports', action: 'update', label: 'Edit Research Report', description: 'Edit existing research report details' },
    'reports.change_public_status': { feature: 'Reports', action: 'change_public_status', label: 'Publish / Unpublish Report', description: 'Toggle public visibility of report' },
    'reports.delete': { feature: 'Reports', action: 'delete', label: 'Delete Report', description: 'Permanently remove research report' },
    'reports.trading_call_popup': { feature: 'Reports', action: 'trading_call_popup', label: 'Trading Call Notification Popup', description: 'Receive real-time popup notifications when new trading calls or reports are published' },

    // Module 7: Staff Management
    'staff.view': { feature: 'Staff', action: 'view', label: 'View Staff Directory', description: 'List staff members and view profiles' },
    'staff.create': { feature: 'Staff', action: 'create', label: 'Add Staff Member', description: 'Create new staff employee account' },
    'staff.update': { feature: 'Staff', action: 'update', label: 'Edit Staff Details', description: 'Update staff role, department, or profile' },
    'staff.reset_mpin': { feature: 'Staff', action: 'reset_mpin', label: 'Reset Staff MPIN', description: 'Admin reset credentials / MPIN for staff' },
    'staff.assignment': { feature: 'Staff', action: 'assignment', label: 'Reassign Clients to Staff', description: 'Bulk reassign client portfolio to staff' },
    'staff.delete': { feature: 'Staff', action: 'delete', label: 'Delete / Deactivate Staff', description: 'Deactivate or remove staff account' },
    'staff.view_applicants': { feature: 'Staff', action: 'view_applicants', label: 'View Job Applicants', description: 'View onboarding applicant queue' },
    'staff.approve_applicant': { feature: 'Staff', action: 'approve_applicant', label: 'Approve Applicant', description: 'Approve applicant to full employee' },

    // Module 8: Notifications
    'notifications.view': { feature: 'Notifications', action: 'view', label: 'View Notifications History', description: 'View sent notifications log' },
    'notifications.send': { feature: 'Notifications', action: 'send', label: 'Send Push Notification', description: 'Dispatch mobile push notification' },
    'notifications.send_bulk_email': { feature: 'Notifications', action: 'send_bulk_email', label: 'Send Bulk Email Blast', description: 'Send email campaigns to clients' },
    'notifications.preview': { feature: 'Notifications', action: 'preview', label: 'Preview Email Template', description: 'Preview formatted email template' },
    'notifications.cancel_scheduled': { feature: 'Notifications', action: 'cancel_scheduled', label: 'Cancel Scheduled Alert', description: 'Cancel pending scheduled alert' },

    // Module 9: System Settings
    'settings.view': { feature: 'Settings', action: 'view', label: 'View System Settings', description: 'View company settings and policies' },
    'settings.update': { feature: 'Settings', action: 'update', label: 'Update System Settings', description: 'Modify and save system configurations' },
    'settings.upload_payment_qr': { feature: 'Settings', action: 'upload_payment_qr', label: 'Upload Payment QR Code', description: 'Update official payment QR code image' }
};

export const isValidPermissionKey = (key) => Object.prototype.hasOwnProperty.call(PERMISSION_REGISTRY, key);
