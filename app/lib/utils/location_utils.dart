import 'dart:math';

class IndianCity {
  final String name;
  final double latitude;
  final double longitude;

  const IndianCity(this.name, this.latitude, this.longitude);
}

const List<IndianCity> indianCities = [
  // ── Gujarat ────────────────────────────────────────────────────────────────
  IndianCity('Ahmedabad', 23.0225, 72.5714),
  IndianCity('Anand', 22.5645, 72.9289),
  IndianCity('Vadodara', 22.3072, 73.1812),
  IndianCity('Surat', 21.1702, 72.8311),
  IndianCity('Rajkot', 22.3039, 70.8022),
  IndianCity('Bhavnagar', 21.7645, 72.1519),
  IndianCity('Gandhinagar', 23.2156, 72.6369),
  IndianCity('Jamnagar', 22.4707, 70.0577),
  IndianCity('Nadiad', 22.6939, 72.8618),
  IndianCity('Morbi', 22.8156, 70.8364),
  IndianCity('Bharuch', 21.7051, 72.9959),
  IndianCity('Navsari', 20.9467, 72.9520),
  IndianCity('Valsad', 20.6095, 72.9155),
  IndianCity('Palanpur', 24.1707, 72.4375),
  IndianCity('Mehsana', 23.5880, 72.3693),
  IndianCity('Surendranagar', 22.7271, 71.6487),
  IndianCity('Junagadh', 21.5222, 70.4579),
  IndianCity('Porbandar', 21.6417, 69.6293),
  IndianCity('Bhuj', 23.2420, 69.6669),
  IndianCity('Vidyanagar', 22.5614, 72.9600),
  IndianCity('Vasad', 22.4511, 73.0711),

  // ── Major Metros ───────────────────────────────────────────────────────────
  IndianCity('Mumbai', 19.0760, 72.8777),
  IndianCity('Pune', 18.5204, 73.8567),
  IndianCity('Delhi', 28.7041, 77.1025),
  IndianCity('Bangalore', 12.9716, 77.5946),
  IndianCity('Chennai', 13.0827, 80.2707),
  IndianCity('Hyderabad', 17.3850, 78.4867),
  IndianCity('Kolkata', 22.5726, 88.3639),
  IndianCity('Jaipur', 26.9124, 75.7873),
  IndianCity('Lucknow', 26.8467, 80.9462),
  IndianCity('Indore', 22.7196, 75.8577),
  IndianCity('Bhopal', 23.2599, 77.4126),
  IndianCity('Chandigarh', 30.7333, 76.7794),
  IndianCity('Nagpur', 21.1458, 79.0882),
  IndianCity('Thane', 19.2183, 72.9781),
  IndianCity('Nashik', 19.9975, 73.7898),
];

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}

double? getCityLatitude(String cityName) {
  final city = indianCities.cast<IndianCity?>().firstWhere(
        (c) => c!.name.toLowerCase() == cityName.toLowerCase(),
        orElse: () => null,
      );
  return city?.latitude;
}

double? getCityLongitude(String cityName) {
  final city = indianCities.cast<IndianCity?>().firstWhere(
        (c) => c!.name.toLowerCase() == cityName.toLowerCase(),
        orElse: () => null,
      );
  return city?.longitude;
}

List<String> getCityNames() {
  return indianCities.map((c) => c.name).toList();
}
