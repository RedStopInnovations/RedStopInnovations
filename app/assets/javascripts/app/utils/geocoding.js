var Geocoding = {

  /**
   * Get distance in km between latitude-longitude points use Haversine formula
   * Usage: Geocoding.distanceBetween([lat1, lng1], [lat2, lng2])
   * @see: https://stackoverflow.com/a/27943/7538004
   */
  distanceBetween: function(latLng1, latLng2) {
    function deg2rad(deg) {
      return deg * (Math.PI / 180);
    }

    var lat1 = latLng1[0];
    var lng1 = latLng1[1];

    var lat2 = latLng2[0];
    var lng2 = latLng2[1];

    var dLat = deg2rad(lat2 - lat1);
    var dLon = deg2rad(lng2 - lng1);
    var a =
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return 6371 * c;
  }
};
