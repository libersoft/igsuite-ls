//Standard Analogue Clock - http://www.btinternet.com/~kurt.grigg/javascript

if  ((document.getElementById) && 
window.addEventListener || window.attachEvent){

(function(){

var fCol="#000000"; //face colour.
var dCol="#dddddd"; //dots colour.
var hCol="#000000"; //hours colour.
var mCol="#000000"; //minutes colour.
var sCol="#f11111"; //seconds colour.

//Alter nothing below! Alignments will be lost!

var dial = "3 4 5 6 7 8 9 10 11 12 1 2";
dial = dial.split(" ");
var e = 360/dial.length;
var h = 3;
var m = 4;
var s = 5;
var y = 50;
var x = 50;
var cyx = 30/4;
var theDial = [];
var theDots = [];
var theHours = [];
var theMinutes = [];
var theSeconds = [];
var idx = document.getElementsByTagName('div').length;
var pix = "px";

document.write('<div style="position:relative;width:'+(x*2)+'px;height:'+(y*2)+'px">');

for (i=0; i < dial.length; i++){
document.write('<div id="F'+(idx+i)+'" style="position:absolute;top:0px;left:0px;width:15px;height:15px;'
+'font-family:arial,sans-serif;font-size:10px;color:'+fCol+';text-align:center">'+dial[i]+'<\/div>');

document.write('<div id="D'+(idx+i)+'" style="position:absolute;top:0px;left:0px;'
+'width:2px;height:2px;font-size:2px;background-color:'+dCol+'"><\/div>');
}

for (i=0; i < h; i++){
document.write('<div id="H'+(idx+i)+'" style="position:absolute;top:0px;left:0px;'
+'width:2px;height:2px;font-size:2px;background-color:'+hCol+'"><\/div>');
}

for (i=0; i < m; i++){
document.write('<div id="M'+(idx+i)+'" style="position:absolute;top:0px;left:0px;'
+'width:2px;height:2px;font-size:2px;background-color:'+mCol+'"><\/div>');
}

for (i=0; i < s; i++){
document.write('<div id="S'+(idx+i)+'" style="position:absolute;top:0px;left:0px;'
+'width:2px;height:2px;font-size:2px;background-color:'+sCol+'"><\/div>');
}

document.write('<\/div>');


function clock(){
var time = new Date();

var secs = time.getSeconds();
var secOffSet = secs - 15;
if (secs < 15){ 
 secOffSet = secs+45;
}
var sec = Math.PI * (secOffSet/30);

var mins = time.getMinutes();
var minOffSet = mins - 15;
if (mins < 15){ 
 minOffSet = mins+45;
}
var min = Math.PI * (minOffSet/30);

var hrs = time.getHours();
if (hrs > 12){
 hrs -= 12;
}
var hrOffSet = hrs - 3;
if (hrs < 3){ 
 hrOffSet = hrs+9;
}
var hr = Math.PI * (hrOffSet/6) + Math.PI * time.getMinutes()/360;

for (i=0; i < s; i++){
 theSeconds[i].top = y + (i*cyx) * Math.sin(sec) + pix;
 theSeconds[i].left = x + (i*cyx) * Math.cos(sec) + pix;
}
for (i=0; i < m; i++){
 theMinutes[i].top = y + (i*cyx) * Math.sin(min) + pix;
 theMinutes[i].left = x + (i*cyx) * Math.cos(min) + pix;
}
for (i=0; i < h; i++){
 theHours[i].top = y + (i*cyx) * Math.sin(hr) + pix;
 theHours[i].left = x + (i*cyx) * Math.cos(hr) + pix;
}
setTimeout(clock,100);
}




 
function init(){
for (i=0; i < dial.length; i++){
 theDial[i] = document.getElementById("F"+(idx+i)).style;
 theDial[i].top = y-6 + 30 * 1.4  * Math.sin(i*e*Math.PI/180) + pix;
 theDial[i].left = x-6 + 30 * 1.4 * Math.cos(i*e*Math.PI/180) + pix;
 theDots[i] = document.getElementById("D"+(idx+i)).style;
 theDots[i].top = y + 30 * Math.sin(e*i*Math.PI/180) + pix;
 theDots[i].left= x + 30 * Math.cos(e*i*Math.PI/180) + pix;
}
for (i=0; i < h; i++){
 theHours[i] = document.getElementById("H"+(idx+i)).style;
}
for (i=0; i < m; i++){
 theMinutes[i] = document.getElementById("M"+(idx+i)).style;
}
for (i=0; i < s; i++){
 theSeconds[i] = document.getElementById("S"+(idx+i)).style;
}
clock();
}

if (window.addEventListener){
 window.addEventListener("load",init,false);
}
else if (window.attachEvent){
 window.attachEvent("onload",init);
} 
})();
}//End.