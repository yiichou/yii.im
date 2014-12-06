//= require jquery
//= require jquery_ujs

//= require jquery-ui/autocomplete
//= require jquery-ui/effect-blind

//= require jquery-plugins/jquery.cookie
//= require jquery-plugins/jquery.color
//= require jquery-plugins/jquery.hotkeys
//= require rails-timeago
//= require bootstrap

//= require showdown
//= require tag-it
//= require tags

jQuery(function ($) { $(document).ready(function(){

  var showdown = new Showdown.converter()

  $('.tagit').tagit({
    allowSpaces: false,
    removeConfirmation: true,
    tagSource: function (search, showChoices) {
      var _this = this;
      $.ajax({
        url: '/tags.json',
        data: { search: search.term },
        dataType: 'json',
        success: function (choices) {
          choices = choices.map(function(e){return e.title;});
          showChoices(_this._subtractArray(choices, _this.assignedTags()));
        }
      });
    },
  });

  $(document).on('click', '.expanding-button', function(e){
    $($(this).data('target')).slideToggle();
  });

}); });
