var bootstrapModal = {
  created: function() {
    this.$watch('show', function(newVal, oldVal) {
      this.$nextTick(function() {
        var $modalEl = $(this.$el).find('.modal');

        if ($modalEl.length === 0) {
          $modalEl = $(this.$el);
        }
        var zIndexValues = [1060];

        $('.modal.in').each(function() {
          var zidx = $(this).css('z-index');
          if (zidx) {
            zIndexValues.push(parseInt(zidx));
          }
        });

        var zidx = Math.max.apply(null, zIndexValues) + 1;

        if (newVal === false) {
          zidx = '';
        }
        $modalEl.css('z-index', zidx);
      });
    });
  }
};
