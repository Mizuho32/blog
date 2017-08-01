var pagers = $('a.pager');

for (let pager of pagers) {
  pager.onclick = function (event) {
    update(pager);
    event.preventDefault();
  };
}

function update(pager){
  $.ajax({        
      url: "search.cgi",
      type: 'POST',
      data: {
        'page':       pager.innerText.replace(/\s+/, ""),
        'repository': pager.getAttribute("repo"),
        'branch':     pager.getAttribute("branch"),
        'id':         pager.getAttribute("sid"),
      },
      timeout: 10000,
      dataType: 'text'
  }).done(function (data) { //Ajax通信に成功したときの処理
      //alert(`success${data}`);
      $(pager).parent().parent().parent().parent().parent().html(data);
  }).fail(function (data) { //Ajax通信に失敗したときの処理
      alert('update failed');
  }).always(function (data) { //処理が完了した場合の処理
    //alert('always');    
    //hljs.initHighlighting();
    $('pre code').each(function(i, block) {
      hljs.highlightBlock(block);
    });
 });
};

