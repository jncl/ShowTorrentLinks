const myDebug = false;

// array of regular expressions that dictate what is a valid torrent download url
var TORRENT_LINKS = [
    /\.torrent$/i,
    /^magnet:/i
];
var linkHandlersCreated = false;

document.addEventListener("DOMContentLoaded", function(event) {

    if (myDebug) console.log("DOMContentLoaded - links info: [" + document.links.length + ']');

    if (document.links.length > 0) createHandlers4Links("DOMContentLoaded");

});

if (window === top) {
    // The parent frame is the top-level frame, not an iframe.
    // All non-iframe code goes before the closing brace.

    // Handlers
    function clickHandler(event) {
        if (myDebug) console.log("clickHandler", event);

        var linkURL = event.target.href ? event.target.href : event.target.parentElement.href;
        // begin download of torrent
        safari.extension.dispatchMessage("inject", {
            "url": linkURL,
            "method": "torrent-add"
        });

        // stop any further events and the default action of downloading locally
        event.preventDefault();
        event.stopPropagation();

    }

    function contextmenuHandler(event) {
        if (myDebug) console.log("contextmenuHandler", event);

        var linkURL = event.target.href ? event.target.href : event.target.parentElement.href;
        // store torrent url for later use
        safari.extension.setContextMenuEventUserInfo(event, linkURL);

    }

    // create image to indicate link has been tagged
    function createImage() {

        var img = document.createElement("img");
        img.setAttribute("class", "new-window");
        img.setAttribute("src", "data:image/gif;base64," + "R0lGODlhEAAMALMLAL66tBISEjExMdTQyBoaGjs7OyUlJWZmZgAAAMzMzP///////wAAAAAAAAAAAAAA" + "ACH5BAEAAAsALAAAAAAQAAwAAAQ/cMlZqr2Tps13yVJBjOT4gYairqohCTDMsu4iHHgwr7UA/LqdopZS" + "DBBIpGG5lBQH0GgtU9xNJ9XZ1cnsNicRADs=");
        img.setAttribute("style", "width:16px!important;height:12px!important;border:none!important;");
        return img;

    }

    function createHandlers4Links(source) {

        if (myDebug) console.log("createHandlers4Links run from " + source);

        // don't create handlers more than once
        if (linkHandlersCreated) return;

        // add event listeners for torrent/magnet links
        for (var i = document.links.length - 1; i >= 0; i--) {
            for (var j = TORRENT_LINKS.length - 1; j >= 0; j--) {
                //            if (myDebug) console.log('checking links', TORRENT_LINKS[j], document.links[i].href, TORRENT_LINKS[j].test(document.links[i].href));
                if (TORRENT_LINKS[j].test(document.links[i].href)) {
                    // add handlers to link
                    document.links[i].addEventListener("click", clickHandler, true);
                    document.links[i].addEventListener("contextmenu", contextmenuHandler, true);
                    document.links[i].appendChild(createImage());
                    break;
                }
            }
        }

        linkHandlersCreated = true;

    }

    if (myDebug) console.log("injected into " + location.href + " - links info: [" + document.links.length + "]");

    if (document.links.length > 0) createHandlers4Links("injection");

}
