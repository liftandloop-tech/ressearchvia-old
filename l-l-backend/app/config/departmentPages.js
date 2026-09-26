export const AVAILABLE_DEPARTMENT_PAGES = [
    {
        key: 'Leads',
        label: 'Leads & Sales Pools',
        description: 'Lead distribution, pools, bulk import, follow-ups, and pull stats',
        features: ['Leads']
    },
    {
        key: 'Users',
        label: 'Client Management',
        description: 'List clients, client profile updates, suspension, and account credentials',
        features: ['Users']
    },
    {
        key: 'KYC',
        label: 'KYC & Verification',
        description: 'Review KYC submissions, verify documents, and approve/reject KYC status',
        features: ['KYC']
    },
    {
        key: 'Subscriptions',
        label: 'Subscriptions, Plans & Segments',
        description: 'Manage trading segments, subscription plans, and user plan entitlements',
        features: ['Subscriptions', 'Plans', 'Segments']
    },
    {
        key: 'Reports',
        label: 'Research Reports',
        description: 'Upload, publish, edit, and manage market research reports',
        features: ['Reports']
    },
    {
        key: 'Payments',
        label: 'Payments & Approvals',
        description: 'Review bank transfers and verify payment operations',
        features: ['Payments']
    },
    {
        key: 'Notifications',
        label: 'Notifications & Alerts',
        description: 'Broadcast push notifications, send bulk marketing emails, and schedule alerts',
        features: ['Notifications']
    },
    {
        key: 'Staff',
        label: 'Staff Management & Recruitment',
        description: 'Manage staff members, job applicants, onboarding, and assignments',
        features: ['Staff']
    },
    {
        key: 'Settings',
        label: 'System Settings & RBAC',
        description: 'System configurations, roles, permission groups, and department controls',
        features: ['Settings', 'Roles', 'PermissionGroups']
    }
];

export const getFeaturesForPages = (pageKeys = []) => {
    const featureSet = new Set();
    AVAILABLE_DEPARTMENT_PAGES.forEach(page => {
        if (pageKeys.includes(page.key)) {
            page.features.forEach(f => featureSet.add(f));
        }
    });
    return Array.from(featureSet);
};
