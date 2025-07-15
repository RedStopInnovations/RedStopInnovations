(function() {
  Vue.filter('formattedLocalAddress', function(hasAddressObject) {
    const parts = [];
    if (hasAddressObject.city) {
        parts.push(hasAddressObject.city);
    }

    if (hasAddressObject.state) {
        parts.push(hasAddressObject.state);
    }

    if (hasAddressObject.postcode) {
        parts.push(hasAddressObject.postcode);
    }

    return parts.join(', ');
  });

  Vue.filter('formattedLocalityAddress', function(hasAddressObject) {
    const parts = [];
    if (hasAddressObject.city) {
        parts.push(hasAddressObject.city);
    }

    if (hasAddressObject.state) {
        parts.push(hasAddressObject.state);
    }

    return parts.join(', ');
  });

})();
