// IGSuite 3.2
// JavaScript functions

// store variables to control where the popup will appear
// relative to the cursor position positive numbers are below and to
// the right of the cursor, negative numbers are above and to the left
var xOffset = 15;
var yOffset = 25;
var lastMouseX;
var lastMouseY;
var lastMouseButton;
var layer = new String();
var style = new String();
var qpv = '[Open Preview]';
var cpv = '[Close Preview]';

// Global needed by protocolInfoBox
var infoBoxTime;
var infoBoxFutureEvent;

// Find screen or frame max width and height
var maxWidth = 500;
var maxHeight = 300;

// Check if a frame exists
function ckFrame(what)
 {
  for (var i=0;i<parent.frames.length;i++)
   {
    if (parent.frames[i].name == what)
     return true;
   }
  return false;
 }
                                  
// Show Protocol Info Box
function protocolInfoBox(elemId, divName, objEvent)
 {
  if(!objEvent) objEvent = window.event;
  infoBoxFutureEvent = objEvent;
  ajaxrequest(['ajaxaction__docinfo','NO_CACHE','id__'+elemId ], [divName]);
  if ( Prototype.Browser.Safari )
   {
    clearTimeout(infoBoxTime);
    var futureShowPopup = "showPopup('" + divName + "', infoBoxFutureEvent, 1)";
    infoBoxTime = setTimeout(futureShowPopup, 1000);
   }
  else
   {
    showPopup(divName, objEvent, 1);
   }
 }

function getElementDimensions(elemID) //#XXX2TEST
 {
  var base = $(elemID);
  var offsetTrail = base;
  var offsetLeft = 0;
  var offsetTop = 0;
  var width = 0;
  var widthOffset = 1;
    
  while (offsetTrail)
   {
    offsetLeft += offsetTrail.offsetLeft;
    offsetTop += offsetTrail.offsetTop;
    offsetTrail = offsetTrail.offsetParent;
   }

  if ( navigator.userAgent.indexOf("Mac") != -1 &&
       typeof document.body.leftMargin != "undefined" )
   {
    offsetLeft += document.body.leftMargin;
    offsetTop += document.body.topMargin;
   }
   
  //if (!isIE)
  // { width =  base.offsetWidth-widthOffset*2; }
  //else
  // { width = base.offsetWidth; }
  
  return { left:offsetLeft, 
           top:offsetTop, 
           width:base.offsetWidth, 
           height:base.offsetHeight,
           bottom:offsetTop + base.offsetHeight, 
           right:offsetLeft + width };
 }


// Generally used by Ajax
function resetDiv( divId )
 {
  document.getElementById(divId).innerHTML = "";
 }


function high(which2)
 {
  theobject = which2;
  highlighting = setInterval("highlightit(theobject)",50);
 }
 
function low(which2)
 {
  clearInterval(highlighting);
  if (which2.style.MozOpacity) which2.style.MozOpacity = 0.3
  else if (which2.filters) which2.filters.alpha.opacity = 30
 }

function highlightit(cur2)
 {
  if (cur2.style.MozOpacity<1)
   cur2.style.MozOpacity = parseFloat(cur2.style.MozOpacity)+0.1
  else if (cur2.filters&&cur2.filters.alpha.opacity<100)
   cur2.filters.alpha.opacity += 10
  else if (window.highlighting)
   clearInterval(highlighting)
 }


// Correctly handle PNG transparency in Win IE 5.5 or higher.
// http://homepage.ntlworld.com/bobosola. Updated 02-March-2004

function correctPNG() 
 {
  for(var i=0; i<document.images.length; i++)
   {
    var img = document.images[i];
    var imgName = img.src.toUpperCase();
    if (imgName.substring(imgName.length-3, imgName.length) == "PNG")
     {
      var imgID = (img.id) ? "id='" + img.id + "' " : "";
      var imgClass = (img.className) ? "class='" + img.className + "' " : "";
      var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' ";
      var imgStyle = "display:inline-block;" + img.style.cssText;
      if (img.align == "left") imgStyle = "float:left;" + imgStyle;
      if (img.align == "right") imgStyle = "float:right;" + imgStyle;
      var strNewHTML = "<span " + imgID + imgClass + imgTitle
       + " style=\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
       + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
       + "(src='" + img.src + "', sizingMethod='scale');\"></span>";
      img.outerHTML = strNewHTML;
     }
   }
 }


function replaceArea(areaname, toolbar, areaWidth, areaHeight)
 {
  if ( !toolbar ) { toolbar='IGBasic'; }
  if ( !areaWidth) { areaWidth='530'; }
  if ( !areaHeight) { areaHeight='530'; }

  var oFCKeditor = new FCKeditor( areaname ) ;
  oFCKeditor.Config["CustomConfigurationsPath"] = "/images/igfckeditor.js";
  oFCKeditor.Config['DefaultLanguage'] = 'it';
  oFCKeditor.ToolbarSet = toolbar;
  oFCKeditor.Height = areaHeight;
  oFCKeditor.Width = areaWidth;
  oFCKeditor.BasePath = '/fckeditor/';
  oFCKeditor.ReplaceTextarea() ;
 }

 
function ckCookie()
 {
  var cookieEnabled = (navigator.cookieEnabled) ? true : false

  //if not IE4+ nor NS6+
  if (typeof navigator.cookieEnabled=="undefined" && !cookieEnabled)
   {
    document.cookie = "testcookie";
    cookieEnabled = (document.cookie.indexOf("testcookie")!=-1)? true : false;
   }

  return (cookieEnabled) ? true : false;
 }                    


function getSize()
 {
  if (self.innerHeight) // all except Explorer
   {
        maxWidth = self.innerWidth;
        maxHeight = self.innerHeight;
   }
  else if (document.documentElement && document.documentElement.clientWidth)
        // Explorer 6 Strict Mode
   {
        maxWidth = document.documentElement.clientWidth;
        maxHeight = document.documentElement.clientHeight;
   }
  else if (document.body) // other Explorers
   {
        maxWidth = document.body.clientWidth;
        maxHeight = document.body.clientHeight;
   }
 }


// Javascript error handler
window.onerror = tellerror;
function tellerror(msg, url, linenumber)
 {
  alert('Error message=['+msg+'] URL=['+url+'] Line Number=['+linenumber+']');
  return true;
 }

// Needed by MkRepository
function pv(url, id, pwidth, pheight, omsg, cmsg)
 {
  qpv = omsg;
  cpv = cmsg;

  if(document.all || document.getElementById)
   {
    document.write('<a title="Click to preview" id="link'+id+'" href="'+url+'" onClick="pview(this,'+pwidth+','+pheight+');return false">'+qpv+'</a>');
   }
 }

function pview(link, pwidth, pheight)
 {
  var iframe = 'if' + link.id;
      iframe = $(iframe);

  if(link.innerHTML == qpv)
   {
    if(iframe)
     {
      // Reuses the IFrame if open already
      iframe.src = link.href;
      iframe.style.height = pheight;
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
      myIframe.setAttribute('height',pheight);
      myIframe.setAttribute('class','pframe');
      myIframe.setAttribute('src',link.href);
      link.parentNode.appendChild(myIframe);
     }
    link.innerHTML = cpv;
   }
  else if(iframe)
   {
    myBR = 'br'+link.id;
    myBR = $(myBR);
    link.innerHTML = qpv;
    link.parentNode.removeChild(iframe);
    link.parentNode.removeChild(myBR);
   }
 }


function setRowBorder(theRow, theBorder)
 {
  var theCells = null;

  // browser can't get the row -> exits
  if ( typeof(theRow.style) == 'undefined' )
   { return false; }

  // Gets the current row and exits if the browser can't get it
  if (typeof(document.getElementsByTagName) != 'undefined')
   { theCells = theRow.getElementsByTagName('td'); }
  else if (typeof(theRow.cells) != 'undefined')
   { theCells = theRow.cells; }
  else
   { return false; }

  var rowCellsCnt  = theCells.length;

  // Sets the new color
  var c = null;
  for (c = 0; c < rowCellsCnt; c++)
   {
     theCells[c].style.borderBottom = theBorder;
   }
  return true;
 }


// to increase or decrease textarea field
function increaseTextArea(thisTextarea, add)
 {
  var dimensions = thisTextarea.getDimensions();
  var newHeight = parseInt(dimensions.height) + add;
  thisTextarea.style.height = newHeight + "px";
 }

function decreaseTextArea(thisTextarea, subtract)
 {
  var dimensions = thisTextarea.getDimensions();

  if ((parseInt(dimensions.height) - subtract) > 20)
   {
    var newHeight = parseInt(dimensions.height) - subtract;
    thisTextarea.style.height = newHeight + "px";
   }
  else
   {
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
   { alert("First select an item to move"); }
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
    if (catList.options[i].selected && !found)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i-1].value;
      catList.options[i].text = catList.options[i-1].text;
      catList.options[i-1].value = oriValue;
      catList.options[i-1].text = oriText;
      catList.selectedIndex = i-1;
      found = true;
     }
   } 

  if( !found )
   { alert("First select an item to move"); }
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
    if (catList.options[i].selected && !found)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i+1].value;
      catList.options[i].text = catList.options[i+1].text;
      catList.options[i+1].value = oriValue;
      catList.options[i+1].text = oriText;
      catList.selectedIndex = i+1;
      found = true;
     }
   }

  if( !found )
   { alert("First select an item to move"); }
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
function goOver(objectId,name)
 {
  if ( !name ) { name='layer'; }
  for ( var i=0; i<=20; i++ )
   {
    var styleObject = getStyleObject(name + i);
    styleObject.visibility = 'hidden';
    styleObject.display = 'none';
   }

  var styleObject = getStyleObject(name + objectId);
  styleObject.visibility = 'inherit';
  styleObject.display = 'block';
  return true;
 }


//validate filed values
function validate(field,pattern,msg)
 {
  var regExpObj = new RegExp(pattern,"g");
  if ( !(regExpObj.test(field.value)) )
   {
    alert (msg);
    field.focus();
    field.select();
   }
 }


function getMouseOptions(e)
 {
  if (navigator.appName.indexOf("Microsoft") != -1) e = window.event;
  lastMouseX = e.screenX;
  lastMouseY = e.screenY;
  lastMouseButton = e.ctrlKey;
 }


function winPopUp(str, Width, Height, title, option)
 {
  if ( !Height ) { Height = '200'; }
  if ( !Width )  { Width  = '200'; }
  if ( !title )  { title  = 'IGSuite'; }
  if ( !option ) { option = 'location=no,status=no,dependent=yes,scrollbars=yes,resizable=yes'; }

  if (lastMouseX - Width < 0)
   { lastMouseX = Width; }
  if (lastMouseY + Height > screen.height)
   { lastMouseY -= (lastMouseY + Height + 50) - screen.height; }
  lastMouseX -= Width;
  lastMouseY += 10;

  option += ",height=" + Height + ",width=" + Width;
  option += ",left=" + lastMouseX + ",top=" + lastMouseY;
  var newwindow = window.open(str, title, option);

  if (!newwindow)
   {
    alert("A popup window could not be opened. Your browser may be blocking popups for this application.");
   }
  else
   {
    if ( typeof newwindow.name == 'undefined')
     { newwindow.name = title; }

    // In some browsers, setting the "window.opener" property to any window
    // object will make the browser believe that the window was opened with
    // Javascript so we can close it without warnings message.
    if (typeof newwindow.opener == 'undefined')
     { newwindow.opener = self; }
   }

  // return newwindow;
 }


function showPopup (targetObjectId, eventObj, objAutoHide, objWidth, objHeight)
 {
  if (!eventObj) var eventObj = window.event;

  // hide any currently-visible popups
  hideCurrentPopup();

  // stop event from bubbling up any farther
  eventObj.cancelBubble = true;
  if (eventObj.stopPropagation) eventObj.stopPropagation();

  // set a display:block attribute to the object
  changeObjectVisibility(targetObjectId, 'hidden', 'block');

  // refresh screen size available
  getSize();

  var pos = getElementDimensions(targetObjectId);
  if (!objWidth) var objWidth = pos.width;
  if (!objHeight) var objHeight = pos.height;

  // move popup div to current cursor position 
  // (add scrollTop to account for scrolling for IE)
  var posx = 0;
  var posy = 0;

  if (eventObj.pageX || eventObj.pageY)
   {
    posx = eventObj.pageX + xOffset;
    posy = eventObj.pageY + yOffset;
   }
  else if (eventObj.clientX || eventObj.clientY)
   {
    // posx = eventObj.clientX + document.body.scrollLeft + xOffset;
    // posy = eventObj.clientY + document.body.scrollTop + yOffset;
    posx = eventObj.clientX + document.body.scrollLeft + document.documentElement.scrollLeft + xOffset;
    posy = eventObj.clientY + document.body.scrollTop + document.documentElement.scrollTop + yOffset;
   }

  // modify coordinate if it's out of screen
  if (( posx + objWidth + 10) > maxWidth)
   {
    posx = posx - objWidth - 30;
   }

  // modify coordinate if it's out of screen
  if ((posy + objHeight + 10) > maxHeight)
   {
    posy = posy - objHeight - 30;
   }

  moveObject(targetObjectId, posx, posy);

  // and make it visible
  if( changeObjectVisibility(targetObjectId, 'visible', 'block') )
   {
    // if we successfully showed the popup
    // store its Id on a globally-accessible object
    if( objAutoHide ) window.currentlyVisiblePopup = targetObjectId;
    return true;
   }
  else
   {
    // we couldn't show the popup, boo hoo!
    return false;
   }
 }


function placePopup (targetObjectId, posXPopup, posYPopup, objAutoHide)
 {
  moveObject(targetObjectId, posXPopup, posYPopup);

  // and make it visible
  if( changeObjectVisibility(targetObjectId, 'visible', 'block') )
   {
    // if we successfully showed the popup
    // store its Id on a globally-accessible object
    if( objAutoHide ) window.currentlyVisiblePopup = targetObjectId;
    return true;
   }
  else
   {
    // we couldn't show the popup, boo hoo!
    return false;
   }
 }


function hideCurrentPopup()
 {
  // note: we've stored the currently-visible popup on the
  // global object window.currentlyVisiblePopup
  if(window.currentlyVisiblePopup)
   {
    changeObjectVisibility(window.currentlyVisiblePopup, 'hidden', 'none');
    window.currentlyVisiblePopup = false;
   }
 }


function hideThisPopup (targetObjectId)
 {
  if(targetObjectId)
   {
    changeObjectVisibility(targetObjectId, 'hidden', 'none');
   }
 }

function mkImgThumbs(imgList)
 {
  for (i=0; i<imgList.length; i++)
   {
    ajxImgThumbReq.delay(((i*2)+1), i, imgList);
   }
 }

function ajxImgThumbReq(imgIdx, imgList)
 {
   new Ajax.Request(imgUpdateUrl + imgList[imgIdx],
                    {
                     method:'get',
                     onSuccess: function(transport)
                      {
                       var s = transport.responseText || "";
                       if ( s )
                        {
                         $(s).src = imgThumbUrl + s + '.png';
                         $('qe_' + s).src = imgThumbUrl + s + '.png';
                        }
                      }
                    }
                   );
 }



// ***********************
// hacks and workarounds *
// ***********************

// setup an event handler to hide popups for generic clicks on the document
document.onclick = hideCurrentPopup;


// ************************
// layer utility routines *
// ************************


function getStyleObject(objectId)
 {
  var objectId = $(objectId);
  return objectId ? objectId.style : false;
 }


function changeObjectVisibility(objectId, newVisibility, newDisplay)
 {
  var styleObject = getStyleObject(objectId);
  if ( styleObject )
   {
    styleObject.visibility = newVisibility;
    styleObject.display = newDisplay;
    return true;
   }
  else
   {
    return false;
   }
 }


function moveObject(objectId, newXCoordinate, newYCoordinate)
 {
  // get a reference to the cross-browser style object and make sure the object exists
  var styleObject = getStyleObject(objectId);
  if(styleObject)
   {
    if (newXCoordinate < 0)
     { newXCoordinate = 1; }
 
    if (newYCoordinate < 0)
     { newYCoordinate = 1; }

    styleObject.left = newXCoordinate;
    styleObject.top = newYCoordinate;
    return true;
   }
  else
   {
    // we couldn't find the object, so we can't very well move it
    return false;
   }
 }

