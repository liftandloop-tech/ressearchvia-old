export const PERMISSION_REGISTRY = {
    // Module 1: Leads & CRM
    'leads.create': { feature: 'Leads', action: 'create', label: 'Create Lead', description: 'Create a single lead' },
    'leads.create_pool': { feature: 'Leads', action: 'create_pool', label: 'Create Lead Pool', description: 'Create a lead distribution pool' },
    'leads.bulk_upload': { feature: 'Leads', action: 'bulk_upload', label: 'Bulk Upload Leads', description: 'Bulk upload leads from file' },
    'leads.view_all': { feature: 'Leads', action: 'view_all', label: 'View All Leads', description: 'List and view all sales leads' },
    'leads.view_assigned': { feature: 'Leads', action: 'view_assigned', label: 'View Assigned Leads', description: 'List and view leads assigned to current staff' },
    'leads.view_pools': { feature: 'Leads', action: 'view_pools', label: 'View Lead Pools', description: 'View lead distribution pools' },
    'leads.view_import_status': { feature: 'Leads', action: 'view_import_status', label: 'View Import Status', description: 'View progress of lead import' },
    'leads.update_all': { feature: 'Leads', action: 'update_all', label: 'Update All Leads', description: 'Update details of any sales lead' },
    'leads.update_assigned': { feature: 'Leads', action: 'update_assigned', label: 'Update Assigned Leads', description: 'Update details of assigned sales leads' },
    'leads.bulk_assign': { feature: 'Leads', action: 'bulk_assign', label: 'Bulk Assign Leads', description: 'Assign multiple leads to RM' },
    'leads.follow_up_all': { feature: 'Leads', action: 'follow_up_all', label: 'Follow Up All Leads', description: 'Add follow-up to any sales lead' },
    'leads.follow_up_assigned': { feature: 'Leads', action: 'follow_up_assigned', label: 'Follow Up Assigned Leads', description: 'Add follow-up to assigned leads' },
    'leads.pull': { feature: 'Leads', action: 'pull', label: 'Pull Leads', description: 'Pull leads from distribution pool' },
    'leads.view_pull_stats': { feature: 'Leads', action: 'view_pull_stats', label: 'View Pull Stats', description: 'View pull statistics overview' },

    // Module 2: Subscriptions, Plans & Segments
    'subscriptions.view': { feature: 'Subscriptions', action: 'view', label: 'View Subscriptions', description: 'View user plan purchases and HNI requests' },
    'subscriptions.activate': { feature: 'Subscriptions', action: 'activate', label: 'Activate Subscription', description: 'Activate user plan subscription' },
    'subscriptions.revoke': { feature: 'Subscriptions', action: 'revoke', label: 'Revoke Subscription', description: 'Revoke user plan subscription' },
    'subscriptions.reject_bank_transfer': { feature: 'Subscriptions', action: 'reject_bank_transfer', label: 'Reject Bank Transfer', description: 'Reject user pending bank transfer' },
    'segments.view': { feature: 'Segments', action: 'view', label: 'View Segments', description: 'View trading segments' },
    'segments.create': { feature: 'Segments', action: 'create', label: 'Create Segment', description: 'Create new trading segment' },
    'segments.update': { feature: 'Segments', action: 'update', label: 'Update Segment', description: 'Update trading segment' },
    'plans.view': { feature: 'Plans', action: 'view', label: 'View Plans', description: 'View subscription plans' },
    'plans.create': { feature: 'Plans', action: 'create', label: 'Create Plan', description: 'Create new subscription plan' },
    'plans.update': { feature: 'Plans', action: 'update', label: 'Update Plan', description: 'Update subscription plan' },
    'plans.delete': { feature: 'Plans', action: 'delete', label: 'Delete Plan', description: 'Delete subscription plan' },

    // Module 3: Roles & Permissions (RBAC Administration)
    'roles.view': { feature: 'Roles', action: 'view', label: 'View Roles', description: 'View system roles' },
    'roles.create': { feature: 'Roles', action: 'create', label: 'Create Role', description: 'Create new system role' },
    'roles.update': { feature: 'Roles', action: 'update', label: 'Update Role', description: 'Update system role' },
    'roles.delete': { feature: 'Roles', action: 'delete', label: 'Delete Role', description: 'Delete system role' },
    'permission_groups.view': { feature: 'PermissionGroups', action: 'view', label: 'View Permission Groups', description: 'View permission groups' },
    'permission_groups.create': { feature: 'PermissionGroups', action: 'create', label: 'Create Permission Group', description: 'Create permission group' },
    'permission_groups.update': { feature: 'PermissionGroups', action: 'update', label: 'Update Permission Group', description: 'Update permission group' },
    'permission_groups.delete': { feature: 'PermissionGroups', action: 'delete', label: 'Delete Permission Group', description: 'Delete permission group' },

    // Module 4: Users & Account Security
    'users.create': { feature: 'Users', action: 'create', label: 'Create User', description: 'Provision new client account' },
    'users.view': { feature: 'Users', action: 'view', label: 'View Users', description: 'List registered clients and details' },
    'users.view_assigned': { feature: 'Users', action: 'view_assigned', label: 'View Assigned Users', description: 'View staff assigned client list' },
    'users.update': { feature: 'Users', action: 'update', label: 'Update User', description: 'Update client details' },
    'users.suspend_activate': { feature: 'Users', action: 'suspend_activate', label: 'Suspend/Activate User', description: 'Suspend or activate user account' },
    'users.generate_temp_pin': { feature: 'Users', action: 'generate_temp_pin', label: 'Generate Temp PIN', description: 'Generate temporary MPIN for user' },
    'users.delete': { feature: 'Users', action: 'delete', label: 'Delete User', description: 'Permanently delete user' },

    // Module 5: Staff & Recruitment
    'staff.create': { feature: 'Staff', action: 'create', label: 'Create Staff', description: 'Create staff account' },
    'staff.view': { feature: 'Staff', action: 'view', label: 'View Staff', description: 'List staff members' },
    'staff.update': { feature: 'Staff', action: 'update', label: 'Update Staff', description: 'Update staff profile' },
    'staff.reset': { feature: 'Staff', action: 'reset', label: 'Reset Staff Password', description: 'Reset staff credentials' },
    'staff.assignment': { feature: 'Staff', action: 'assignment', label: 'Staff Assignment', description: 'Reassign clients to staff' },
    'staff.delete': { feature: 'Staff', action: 'delete', label: 'Delete Staff', description: 'Cancel staff account' },
    'staff.upload_video': { feature: 'Staff', action: 'upload_video', label: 'Upload Video', description: 'Upload staff video' },
    'staff.upload_document': { feature: 'Staff', action: 'upload_document', label: 'Upload Document', description: 'Upload staff document' },
    'staff.view_applicants': { feature: 'Staff', action: 'view_applicants', label: 'View Applicants', description: 'View job applicants list' },
    'staff.approve_applicant': { feature: 'Staff', action: 'approve_applicant', label: 'Approve Applicant', description: 'Approve applicant onboarding' },

    // Module 6: KYC
    'kyc.view': { feature: 'KYC', action: 'view', label: 'View KYC', description: 'List pending KYC submissions' },
    'kyc.download_document': { feature: 'KYC', action: 'download_document', label: 'Download KYC Doc', description: 'Download user KYC document' },
    'kyc.change_status': { feature: 'KYC', action: 'change_status', label: 'Change KYC Status', description: 'Approve or reject overall KYC' },
    'kyc.update_gate_status': { feature: 'KYC', action: 'update_gate_status', label: 'Update Gate Status', description: 'Update gate status' },
    'kyc.update_file': { feature: 'KYC', action: 'update_file', label: 'Update KYC File', description: 'Upload replacement KYC document' },

    // Module 7: Payments
    'payments.view_pending': { feature: 'Payments', action: 'view_pending', label: 'View Pending Transfers', description: 'List bank transfers queue' },
    'payments.bypass': { feature: 'Payments', action: 'bypass', label: 'Bypass Payment', description: 'Bypass user payment' },

    // Module 8: Reports
    'reports.create': { feature: 'Reports', action: 'create', label: 'Create Report', description: 'Upload research report' },
    'reports.view': { feature: 'Reports', action: 'view', label: 'View Reports', description: 'List research reports' },
    'reports.update': { feature: 'Reports', action: 'update', label: 'Update Report', description: 'Edit research report' },
    'reports.delete': { feature: 'Reports', action: 'delete', label: 'Delete Report', description: 'Delete research report' },
    'reports.change_public_status': { feature: 'Reports', action: 'change_public_status', label: 'Change Public Status', description: 'Publish or unpublish report' },

    // Module 9: Notifications
    'notifications.view': { feature: 'Notifications', action: 'view', label: 'View Notifications', description: 'View notifications history' },
    'notifications.send': { feature: 'Notifications', action: 'send', label: 'Send Notification', description: 'Dispatch push notification' },
    'notifications.send_bulk_email': { feature: 'Notifications', action: 'send_bulk_email', label: 'Send Bulk Email', description: 'Send bulk email blast' },
    'notifications.preview': { feature: 'Notifications', action: 'preview', label: 'Preview Email', description: 'Preview email layout' },
    'notifications.view_scheduled': { feature: 'Notifications', action: 'view_scheduled', label: 'View Scheduled Alerts', description: 'View scheduled alerts queue' },
    'notifications.cancel_scheduled': { feature: 'Notifications', action: 'cancel_scheduled', label: 'Cancel Scheduled Alert', description: 'Cancel scheduled alert' },

    // Module 10: System Settings
    'settings.view': { feature: 'Settings', action: 'view', label: 'View Settings', description: 'View system configurations' },
    'settings.update': { feature: 'Settings', action: 'update', label: 'Update Settings', description: 'Save system configurations' },
    'settings.upload_payment_qr': { feature: 'Settings', action: 'upload_payment_qr', label: 'Upload Payment QR', description: 'Upload payment QR image' }
};

export const isValidPermissionKey = (key) => Object.prototype.hasOwnProperty.call(PERMISSION_REGISTRY, key);
