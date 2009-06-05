// IGSuite 3.1
// specific JavaScript functions

// store variables to control where the popup will appear relative to the cursor position
// positive numbers are below and to the right of the cursor, negative numbers are above and to the left
var xOffset = 5;
var yOffset = 25;
var lastMouseX;
var lastMouseY;
var lastMouseButton;
var layer = new String();
var style = new String();
var qpv = '[Open Preview]';
var cpv = '[Close Preview]';

var psize = '250';

function pv(url, id, pwidth, omsg, cmsg)
 {
  // To insert the features
  // <span><script>
  //    pv('http://www.igsuite.org/','1', 600)
  // </script></span>
  qpv = omsg;
  cpv = cmsg;

  if(document.all || document.getElementById)
   {
    document.write('<a title="Click to preview" id="link'+id+'" href="'+url+'" onClick="pview(this,'+pwidth+');return false">'+qpv+'</a>');
   }
 }

function pview(link, pwidth)
 {
  // Testing for IE 4, since IE4 does not recognize document.getElementById
  var ie4 = (document.all && !document.getElementById) ? true : false;
  // If it is IE 4, we set document.all. If we are not IE 4 then we use the standard getElementById
  if (ie4 == 1)
   { var iframe = document.all['if'+link.id]; }
  else
   { var iframe = document.getElementById('if'+link.id); }

  if(link.innerHTML == qpv)
   {
    if(iframe)
     {
      // Reuses the IFrame if open already
      iframe.src = link.href;
      iframe.style.height = psize;
      iframe.style.visibility = 'visible';
     }
    else
     {
      // Build the Frame and Load the URL
      myBR = document.createElement('br');
      myBR.setAttribute('id','br'+link.id);
      link.parentNode.appendChild(myBR);
      myIframe = document.createElement('iframe');
      myIframe.setAttribute('id','if'+link.id);
      myIframe.setAttribute('name','myframe');
      myIframe.setAttribute('width','100%');
      myIframe.setAttribute('height',psize);
      myIframe.setAttribute('class','pframe');
      myIframe.setAttribute('src',link.href);
      link.parentNode.appendChild(myIframe);
     }
    link.innerHTML = cpv;
   }
  else if(iframe)
   {
    if (ie4 == 1)
     { myBR = document.all['br'+link.id]; }
    else
     { myBR = document.getElementById('br'+link.id); }
    link.innerHTML = qpv;
    link.parentNode.removeChild(iframe);
    link.parentNode.removeChild(myBR);
   }
 }


function setRowBorder(theRow, theBorder)
 {
  var theCells = null;

  // 1. the browser can't get the row -> exits
  if ( typeof(theRow.style) == 'undefined' )
   { return false; }


  // 2. Gets the current row and exits if the browser can't get it
  if (typeof(document.getElementsByTagName) != 'undefined')
   { theCells = theRow.getElementsByTagName('td'); }
  else if (typeof(theRow.cells) != 'undefined')
   { theCells = theRow.cells; }
  else
   { return false; }

  var rowCellsCnt  = theCells.length;

  // 3. Sets the new color...
  var c = null;
  for (c = 0; c < rowCellsCnt; c++)
   {
     theCells[c].style.borderBottom = theBorder;
   }
  return true;
 } // end of the 'setRowClr()' function


// to increase or decrease textarea field
function increaseTextArea(thisTextarea, add)
 {
  if (thisTextarea.style.height == '') { thisTextarea.style.height = '50px';}
  newHeight = parseInt(thisTextarea.style.height) + add;
  thisTextarea.style.height = newHeight + "px";
 }

function decreaseTextArea(thisTextarea, subtract)
 {
  if ((parseInt(thisTextarea.style.height) - subtract) > 20)
   {
	newHeight = parseInt(thisTextarea.style.height) - subtract;
	thisTextarea.style.height = newHeight + "px";
   }
  else
   {
	newHeight = 30;
	thisTextarea.style.height = "30px";
   }
 }

// needed by Input multiselect
function moveTo(lform,lname,l1,l2)
 {
  var catList1 = eval('document.' + lform + '.' + lname + l1);
  var catList2 = eval('document.' + lform + '.' + lname + l2);
  var found = false;
  
  for (var i = catList2.length-1; i >= 0; i--)
   {
    if (catList2.options[i].selected)
     {
      var newVal = catList2.options[i].value;
      var newTex = catList2.options[i].text;
      catList1[catList1.length] = new Option(newTex,newVal);
      catList2.options[i] = null;
      found = true;
     }
   }

  if( !found )
   { alert("non sono state selezionate voci"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }

// needed by Input multiselect
function moveUp(lform,lname,l1)
 {
  var catList = eval('document.' + lform + '.' + lname + l1);
  var found = false;

  for (var i = catList.length-1; i >= 0; i--)
   {
    if (catList.options[i].selected)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i-1].value;
      catList.options[i].text = catList.options[i-1].text;
      catList.options[i-1].value = oriValue;
      catList.options[i-1].text = oriText;
      found = true;
     }
   }

  if( !found )
   { alert("non sono state selezionate voci"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }

function moveDown(lform,lname,l1)
 {
  var catList = eval('document.' + lform + '.' + lname + l1);
  var found = false;

  for (var i = catList.length-1; i >= 0; i--)
   {
    if (catList.options[i].selected)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i+1].value;
      catList.options[i].text = catList.options[i+1].text;
      catList.options[i+1].value = oriValue;
      catList.options[i+1].text = oriText;
      found = true;
     }
   }

  if( !found )
   { alert("non sono state selezionate voci"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }

// needed by MkTab to show or hide tabs
function goOver(objectId,name) {
      if ( !name ) { name='layer'; }
      for ( var i=0; i<=20; i++ ) {
        var styleObject = getStyleObject(name + i);
        styleObject.visibility = 'hidden';
        styleObject.display = 'none';
      }
      var styleObject = getStyleObject(name + objectId)
      styleObject.visibility = 'visible';
      styleObject.display = 'block';
      return true;
}

//validate filed values
function validate(field,pattern,msg) {
    var regExpObj = new RegExp(pattern,"g");
    if ( !(regExpObj.test(field.value)) ) {
       alert (msg);
       field.focus();
       field.select();
    }
}

// focus each first writable field of a form
function Focus()
 {
  for (var u = 0; u < document.forms.length; u++)
   {
    for (var i = 0; i < document.forms[u].length; i++ )
     {
      var e = document.forms[u].elements[i];
      if (e.type == "text" || e.type == "password" || e.type == "textarea")
       {
        e.focus();
        return true;
       }
     }
   }
 }

function getMouseOptions(e)
 {
  if (navigator.appName.indexOf("Microsoft") != -1) e = window.event;
  lastMouseX = e.screenX;
  lastMouseY = e.screenY;
  lastMouseButton = e.ctrlKey;
 }


function winPopUp(str,Width,Height,title,option)
 {
  if ( !Height ) { Height='200'; }
  if ( !Width ) { Width='200'; }
  if ( !title ) { title='IGSuite'; }
  if ( !option ) { option='dependent=yes,scrollbars=yes,resizable=yes'; }

  if (lastMouseX - Width < 0)
   { lastMouseX = Width; }
  if (lastMouseY + Height > screen.height)
   { lastMouseY -= (lastMouseY + Height + 50) - screen.height; }
  lastMouseX -= Width;
  lastMouseY += 10;

  option += ",height=" + Height + ",width=" + Width;
  option += ",left=" + lastMouseX + ",top=" + lastMouseY;
  newwindow=window.open(str,title,option);
  // if (window.focus) {newwindow.focus()}
 }


function showPopup (targetObjectId, eventObj)
 {
  if(eventObj)
   {
    // hide any currently-visible popups
    hideCurrentPopup();
    // stop event from bubbling up any farther
    eventObj.cancelBubble = true;
    // move popup div to current cursor position 
    // (add scrollTop to account for scrolling for IE)
    var newXCoordinate = (eventObj.pageX)?eventObj.pageX + xOffset:eventObj.x + xOffset + ((document.body.scrollLeft)?document.body.scrollLeft:0);
    var newYCoordinate = (eventObj.pageY)?eventObj.pageY + yOffset:eventObj.y + yOffset + ((document.body.scrollTop)?document.body.scrollTop:0);
    moveObject(targetObjectId, newXCoordinate, newYCoordinate);
    // and make it visible
    if( changeObjectVisibility(targetObjectId, 'visible') )
     {
      // if we successfully showed the popup
      // store its Id on a globally-accessible object
      window.currentlyVisiblePopup = targetObjectId;
      return true;
     }
    else
     {
      // we couldn't show the popup, boo hoo!
      return false;
     }
   }
  else
   {
    // there was no event object, so we won't be able to position anything, so give up
    return false;
   }
 }

function hideCurrentPopup() {
    // note: we've stored the currently-visible popup on the global object window.currentlyVisiblePopup
    if(window.currentlyVisiblePopup) {
	changeObjectVisibility(window.currentlyVisiblePopup, 'hidden');
	window.currentlyVisiblePopup = false;
    }
} // hideCurrentPopup

// ***********************
// hacks and workarounds *
// ***********************

// initialize hacks whenever the page loads
window.onload = initializeHacks;

// setup an event handler to hide popups for generic clicks on the document
document.onclick = hideCurrentPopup;

function initializeHacks() {
    // this ugly little hack resizes a blank div to make sure you can click
    // anywhere in the window for Mac MSIE 5
    if ((navigator.appVersion.indexOf('MSIE 5') != -1) 
	&& (navigator.platform.indexOf('Mac') != -1)
	&& getStyleObject('blankDiv')) {
	window.onresize = explorerMacResizeFix;
    }
    resizeBlankDiv();
    // this next function creates a placeholder object for older browsers
    createFakeEventObj();
}

function createFakeEventObj() {
    // create a fake event object for older browsers to avoid errors in function call
    // when we need to pass the event object to functions
    if (!window.event) {
	window.event = false;
    }
} // createFakeEventObj

function resizeBlankDiv() {
    // resize blank placeholder div so IE 5 on mac will get all clicks in window
    if ((navigator.appVersion.indexOf('MSIE 5') != -1) 
	&& (navigator.platform.indexOf('Mac') != -1)
	&& getStyleObject('blankDiv')) {
	getStyleObject('blankDiv').width = document.body.clientWidth - 20;
	getStyleObject('blankDiv').height = document.body.clientHeight - 20;
    }
}

function explorerMacResizeFix () {
    location.reload(false);
}

// ************************
// layer utility routines *
// ************************

function getStyleObject(objectId) {
    // cross-browser function to get an object's style object given its id
    if(document.getElementById && document.getElementById(objectId)) {
        // W3C DOM
        return document.getElementById(objectId).style;
    } else if (document.all && document.all(objectId)) {
        // MSIE 4 DOM
        return document.all(objectId).style;
    } else if (document.layers && document.layers[objectId]) {
        // NN 4 DOM.. note: this won't find nested layers
        return document.layers[objectId];
    } else {
        return false;
    }
} // getStyleObject

function changeObjectVisibility(objectId, newVisibility)
 {
  var styleObject = getStyleObject(objectId);
  if(styleObject)
   {
    styleObject.visibility = newVisibility;
    return true;
   }
  else
   {
    return false;
   }
 }

function moveObject(objectId, newXCoordinate, newYCoordinate) {
    // get a reference to the cross-browser style object and make sure the object exists
    var styleObject = getStyleObject(objectId);
    if(styleObject) {
        styleObject.left = newXCoordinate;
        styleObject.top = newYCoordinate;
        return true;
    } else {
        // we couldn't find the object, so we can't very well move it
        return false;
    }
} // moveObject

