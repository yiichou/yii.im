//= require highlight.min

//= require codemirror
//= require codemirror/modes/ruby
//= require codemirror/modes/markdown
//= require codemirror/modes/gfm
//= require codemirror/modes/javascript
//= require codemirror/modes/css
//= require codemirror/modes/htmlmixed
//= require codemirror/modes/shell
//= require codemirror/modes/yaml
//= require codemirror/addons/mode/overlay

//= require showdown
//= require tag-it
//= require tags

jQuery(function ($) { 
  $(document).ready(function(){

    var showdown = new Showdown.converter()
  
    $('textarea').each(function (index, area) {
      var preview = $($(area).data('preview'));
      var editor = CodeMirror.fromTextArea(area, {
        mode: 'gfm',
        theme: 'default',
        tabSize: 2,
        autoFocus: false,
        lineNumbers: false,
        lineWrapping: true,
        matchBrackets: true,
      });

      editor.on('change', function(cm, args) {
        if (preview.length !== 0) {
          preview.html(showdown.makeHtml(cm.getValue()));
          hljs.tabReplace = '<span class="indent">\t</span>';
          $('pre code', preview).each(function(i, e) {hljs.highlightBlock(e, hljs.tabReplace, false)});
        }
      });

      $(document).on('click', '.editor-attach', function(e) {
        e.preventDefault();
        var _n = $(this).data('name');
        var _c = editor.getCursor();
        var _s = "[" + _n + "](" + $(this).data('url') + ")";
        var _ext = _n.substr(_n.lastIndexOf('.') +1).toLowerCase();
        switch (_ext) {
          case 'jpg':
          case 'jpeg':
          case 'png':
          case 'gif':
            editor.replaceRange("!" + _s, _c, _c);
            break;
          default:
            editor.replaceRange(_s, _c, _c);
        }
      });

      $(document).on('content:clear', area, function(e) {
        editor.setValue('');
        editor.getTextArea().value = '';
      });

      var form = $(this).parents('form');

      var formLocal = JSON.stringify(form.serializeArray());
      var saveLocal = function (store) {
        editor.getTextArea().value = editor.getValue();
        var formCurrent = JSON.stringify(form.serializeArray());
        if (formCurrent != formLocal) {
          localStorage.setItem(form.attr('id'), formCurrent);
          formLocal = formCurrent;
        }
      };
      setInterval(saveLocal, 8000);

      var formRemote = JSON.stringify(form.serializeArray());
      var saveRemote = function (store) {
        editor.getTextArea().value = editor.getValue();
        var formCurrent = JSON.stringify(form.serializeArray());
        if (formCurrent != formRemote) {
          $.rails.handleRemote(form);
          formRemote = formCurrent;
        }
      };
      if (form.data('persisted')) {
        setInterval(saveRemote, 480000);
      }
    });

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
    
  }); 
});
