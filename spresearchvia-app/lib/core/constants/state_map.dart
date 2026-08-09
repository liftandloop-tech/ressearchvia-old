const Map<String, String> indianStateCodeMap = {
  '28': 'Andhra Pradesh',
  'AP': 'Andhra Pradesh',
  '35': 'Andaman and Nicobar Islands',
  'AN': 'Andaman and Nicobar Islands',
  '12': 'Arunachal Pradesh',
  'AR': 'Arunachal Pradesh',
  '18': 'Assam',
  'AS': 'Assam',
  '10': 'Bihar',
  'BR': 'Bihar',
  '04': 'Chandigarh',
  'CH': 'Chandigarh',
  '22': 'Chhattisgarh',
  'CG': 'Chhattisgarh',
  '26': 'Dadra and Nagar Haveli and Daman and Diu', // Merged
  'DN': 'Dadra and Nagar Haveli and Daman and Diu', // Legacy code
  'DD': 'Dadra and Nagar Haveli and Daman and Diu', // Legacy code
  '07': 'Delhi',
  'DL': 'Delhi',
  '30': 'Goa',
  'GA': 'Goa',
  '24': 'Gujarat',
  'GJ': 'Gujarat',
  '06': 'Haryana',
  'HR': 'Haryana',
  '02': 'Himachal Pradesh',
  'HP': 'Himachal Pradesh',
  '01': 'Jammu and Kashmir',
  'JK': 'Jammu and Kashmir',
  '20': 'Jharkhand',
  'JH': 'Jharkhand',
  '29': 'Karnataka',
  'KA': 'Karnataka',
  '32': 'Kerala',
  'KL': 'Kerala',
  '31': 'Lakshadweep',
  'LD': 'Lakshadweep',
  '23': 'Madhya Pradesh',
  'MP': 'Madhya Pradesh',
  '27': 'Maharashtra',
  'MH': 'Maharashtra',
  '14': 'Manipur',
  'MN': 'Manipur',
  '17': 'Meghalaya',
  'ML': 'Meghalaya',
  '15': 'Mizoram',
  'MZ': 'Mizoram',
  '13': 'Nagaland',
  'NL': 'Nagaland',
  '21': 'Odisha',
  'OR': 'Odisha',
  'OD': 'Odisha',
  '34': 'Puducherry',
  'PY': 'Puducherry',
  '03': 'Punjab',
  'PB': 'Punjab',
  '08': 'Rajasthan',
  'RJ': 'Rajasthan',
  '11': 'Sikkim',
  'SK': 'Sikkim',
  '33': 'Tamil Nadu',
  'TN': 'Tamil Nadu',
  '36': 'Telangana',
  'TS': 'Telangana',
  '16': 'Tripura',
  'TR': 'Tripura',
  '09': 'Uttar Pradesh',
  'UP': 'Uttar Pradesh',
  '05': 'Uttarakhand',
  'UK': 'Uttarakhand',
  'UA': 'Uttarakhand',
  '19': 'West Bengal',
  'WB': 'West Bengal',
  '37': 'Ladakh',
  'LA': 'Ladakh',
};

String? getStateNameFromCode(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  final cleanCode = code.trim().toUpperCase();

  // Try direct lookup first
  if (indianStateCodeMap.containsKey(cleanCode)) {
    return indianStateCodeMap[cleanCode];
  }

  // Try numeric parsing (e.g. if code is "023", try "23")
  final intCode = int.tryParse(cleanCode);
  if (intCode != null) {
      // Try padded version '01', '02', etc. (standard map keys)
      final paddedCode = intCode.toString().padLeft(2, '0');
      if (indianStateCodeMap.containsKey(paddedCode)) {
          return indianStateCodeMap[paddedCode];
      }
      // Try unpadded version '1', '2', etc. (if map has them, currently only '01'..)
      // The map has '01', '02'.. so padded is correct.
      // But maybe map keys are '1', '2' somewhere? No, looking at file they are '01', '02'.
      
      // Also check simple stringint
      final stringInt = intCode.toString();
      if (indianStateCodeMap.containsKey(stringInt)) {
          return indianStateCodeMap[stringInt];
      }
  }

  return cleanCode;
}
