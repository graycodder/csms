class BusinessTerminology {
  final String subscriptionLabel;
  final String planLabel;
  final String renewActionLabel;
  final String customerLabel;
  final String reminderMessageTemplate;

  const BusinessTerminology({
    required this.subscriptionLabel,
    required this.planLabel,
    required this.renewActionLabel,
    required this.customerLabel,
    required this.reminderMessageTemplate,
  });
}

class TerminologyHelper {
  static const Map<String, BusinessTerminology> _mappings = {
    'Health and Fitness': BusinessTerminology(
      subscriptionLabel: 'Membership',
      planLabel: 'Plan',
      renewActionLabel: 'Renew Membership',
      customerLabel: 'Member',
      reminderMessageTemplate: "Dear {customer_name},\n\nThis is a friendly reminder from {shop_name} regarding your {sub_label}. Your {plan_label} for {product_name} is scheduled to expire in {days_left} days, on {end_date}.\n\nTo ensure uninterrupted access to our facilities, please {renew_label} at your earliest convenience.\n\nThank you!",
    ),
    'Automobile Shop': BusinessTerminology(
      subscriptionLabel: 'Service/AMC',
      planLabel: 'Package',
      renewActionLabel: 'Renew Service',
      customerLabel: 'Client',
      reminderMessageTemplate: "Dear {customer_name},\n\nYour {shop_name} {sub_label} for {product_name} is due for renewal. It is scheduled to expire in {days_left} days ({end_date}).\n\nTo keep your vehicle in top condition, please {renew_label} soon.\n\nBest regards,\n{shop_name}",
    ),
    'Insurance Renewal': BusinessTerminology(
      subscriptionLabel: 'Policy',
      planLabel: 'Plan',
      renewActionLabel: 'Renew Policy',
      customerLabel: 'Policy Holder',
      reminderMessageTemplate: "Dear {customer_name},\n\nYour {sub_label} ({product_name}) with {shop_name} is expiring in {days_left} days on {end_date}.\n\nPlease {renew_label} to ensure continuous coverage.\n\nRegards,\n{shop_name}",
    ),
    'Cable TV Operator': BusinessTerminology(
      subscriptionLabel: 'Subscription',
      planLabel: 'Pack',
      renewActionLabel: 'Recharge',
      customerLabel: 'Subscriber',
      reminderMessageTemplate: "Dear {customer_name},\n\nYour {shop_name} {plan_label} ({product_name}) will expire in {days_left} days on {end_date}.\n\nPlease {renew_label} now to avoid any service interruption.\n\nThank you!",
    ),
    'Collection Agency': BusinessTerminology(
      subscriptionLabel: 'Account',
      planLabel: 'Service',
      renewActionLabel: 'Renew Service',
      customerLabel: 'Client',
      reminderMessageTemplate: "Dear {customer_name},\n\nThis is a reminder regarding your {sub_label} for {product_name} with {shop_name}, which expires on {end_date}.\n\nPlease {renew_label} to continue using our services.\n\nThank you.",
    ),
  };

  static const BusinessTerminology _default = BusinessTerminology(
    subscriptionLabel: 'Subscription',
    planLabel: 'Plan',
    renewActionLabel: 'Renew',
    customerLabel: 'Customer',
    reminderMessageTemplate: "Dear {customer_name},\n\nYour {sub_label} for {product_name} at {shop_name} is expiring in {days_left} days on {end_date}.\n\nPlease {renew_label} at your earliest convenience.\n\nThank you!",
  );

  static BusinessTerminology getTerminology(String category) {
    return _mappings[category] ?? _default;
  }
  
  static List<String> get categories => _mappings.keys.toList()..add('Other');
}
