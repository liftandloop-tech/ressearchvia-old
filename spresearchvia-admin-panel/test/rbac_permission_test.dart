import 'package:flutter_test/flutter_test.dart';
import 'package:spresearch_web/models/user.model.dart';

void main() {
  group('RBAC UserModel Permission Tests', () {
    test('1. Admin user has full access', () {
      final admin = UserModel.fromJson({
        '_id': 'admin1',
        'fullName': 'Admin User',
        'deparment': 'Administration',
        'role': 'Admin',
        'isAdmin': true,
      });

      expect(admin.isAdmin, isTrue);
      expect(admin.hasPermission('Leads', 'read'), isTrue);
      expect(admin.hasPermission('Users', 'read'), isTrue);
      expect(admin.hasPermission('Staff', 'read'), isTrue);
      expect(admin.hasPermission('Reports', 'read'), isTrue);
      expect(admin.has('leads.view'), isTrue);
      expect(admin.has('settings.view'), isTrue);
    });

    test('2. Sales BDE has access to Leads & Users, but NOT Staff or Settings', () {
      final bde = UserModel.fromJson({
        '_id': 'bde1',
        'fullName': 'Sales BDE',
        'deparment': 'Sales',
        'role': 'BDE',
        'roleId': {
          '_id': 'role_bde',
          'name': 'BDE',
          'permissionGroups': [
            {
              '_id': 'pg_sales_basic',
              'name': 'SALES_BASIC',
              'permissions': [
                {
                  'feature': 'Reports',
                  'actions': ['reports.view', 'reports.trading_call_popup']
                },
                {
                  'feature': 'Notifications',
                  'actions': ['notifications.view', 'notifications.preview']
                }
              ]
            },
            {
              '_id': 'pg_sales_lead_basic',
              'name': 'SALES_LEAD_BASIC',
              'permissions': [
                {
                  'feature': 'Leads',
                  'actions': ['leads.view', 'leads.pull', 'leads.create', 'leads.update', 'leads.follow_up']
                },
                {
                  'feature': 'Users',
                  'actions': ['users.view']
                }
              ]
            }
          ]
        }
      });

      expect(bde.isAdmin, isFalse);

      // MainDashboardController route check tests
      expect(bde.hasPermission('Leads', 'read'), isTrue, reason: 'BDE must have read access to Leads');
      expect(bde.hasPermission('Users', 'read'), isTrue, reason: 'BDE must have read access to Users');
      expect(bde.hasPermission('Reports', 'read'), isTrue, reason: 'BDE must have read access to Reports');
      expect(bde.hasPermission('Notifications', 'read'), isTrue, reason: 'BDE must have read access to Notifications');

      // Direct action / navbar checks
      expect(bde.has('leads.view'), isTrue);
      expect(bde.has('leads.view_all'), isTrue, reason: 'leads.view satisfies view_all alias');
      expect(bde.has('leads.view_assigned'), isTrue, reason: 'leads.view satisfies view_assigned alias');
      expect(bde.has('leads.pull'), isTrue);
      expect(bde.has('users.view'), isTrue);
      expect(bde.has('reports.view'), isTrue);

      // Restricted areas
      expect(bde.hasPermission('Staff', 'read'), isFalse, reason: 'BDE should not have access to Staff');
      expect(bde.hasPermission('Settings', 'read'), isFalse, reason: 'BDE should not have access to Settings');
      expect(bde.has('staff.view'), isFalse);
    });

    test('3. Research Analyst has access to Reports & Notifications, but NOT Leads or Staff', () {
      final ra = UserModel.fromJson({
        '_id': 'ra1',
        'fullName': 'Analyst User',
        'deparment': 'Research Analyst',
        'role': 'Research Analyst',
        'roleId': {
          '_id': 'role_ra',
          'name': 'Research Analyst',
          'permissionGroups': [
            {
              '_id': 'pg_ra_basic',
              'name': 'RA_RESEARCH_BASIC',
              'permissions': [
                {
                  'feature': 'Reports',
                  'actions': ['reports.view', 'reports.trading_call_popup']
                },
                {
                  'feature': 'Notifications',
                  'actions': ['notifications.view', 'notifications.preview']
                }
              ]
            }
          ]
        }
      });

      expect(ra.isAdmin, isFalse);
      expect(ra.isResearcher, isTrue);

      // Route check tests
      expect(ra.hasPermission('Reports', 'read'), isTrue);
      expect(ra.hasPermission('Notifications', 'read'), isTrue);
      expect(ra.has('reports.view'), isTrue);
      expect(ra.has('reports.trading_call_popup'), isTrue);

      // Forbidden
      expect(ra.hasPermission('Leads', 'read'), isFalse);
      expect(ra.hasPermission('Staff', 'read'), isFalse);
      expect(ra.hasPermission('Settings', 'read'), isFalse);
    });

    test('4. HR Executive has access to Staff, but NOT Leads or Settings', () {
      final hr = UserModel.fromJson({
        '_id': 'hr1',
        'fullName': 'HR Exec',
        'deparment': 'Human Resources',
        'role': 'HR Executive',
        'roleId': {
          '_id': 'role_hr',
          'name': 'HR Executive',
          'permissionGroups': [
            {
              '_id': 'pg_hr_basic',
              'name': 'HR_STAFF_MANAGEMENT',
              'permissions': [
                {
                  'feature': 'Staff',
                  'actions': ['staff.view', 'staff.create', 'staff.assignment', 'staff.view_applicants']
                },
                {
                  'feature': 'Attendance',
                  'actions': ['attendance.view', 'attendance.mark']
                }
              ]
            }
          ]
        }
      });

      expect(hr.isAdmin, isFalse);

      // Route checks
      expect(hr.hasPermission('Staff', 'read'), isTrue);
      expect(hr.hasPermission('Attendance', 'read'), isTrue);
      expect(hr.has('staff.view'), isTrue);

      // Forbidden
      expect(hr.hasPermission('Leads', 'read'), isFalse);
      expect(hr.hasPermission('Settings', 'read'), isFalse);
    });
  });
}
