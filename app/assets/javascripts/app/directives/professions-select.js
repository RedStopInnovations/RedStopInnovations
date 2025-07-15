(function() {
  var PROFESSIONS = [
    "Physiotherapist",
    "Podiatrist",
    "Occupational Therapist",
    "Psychologist",
    "Dietitian",
    "Exercise Physiologist",
    "Speech Therapist",
    "Social Worker",
    "Doctor",
    "Registered Nurse",
    "Enrolled Nurse",
    "Case Manager",
    "Massage Therapist",
    "Myotherapist",
    "Therapy Assistant",
    "Support Worker",
    "Acupuncturist",
    "Osteopath",
    "Chiropractor"
  ];
  Vue.directive('profession-select', {
    bind: function(el, binding, vnode) {
      var profs = PROFESSIONS;
      if (binding.value) {
        profs = binding.value;
      }
      var $el = $(el);
      for (var i = 0; i < profs.length; i++) {
        $el.append($('<option>', {
          value: profs[i],
          text: profs[i]
        }));
      }
    }
  });
})();
