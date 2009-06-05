// IGSuite 3.2
// JavaScript functions to highlight search terms


function highlightSearchTerms(terms) {
    if (!terms){return false};

    var startnode = document.getElementById('page-content');
    if (!startnode){return false};
    var splitted_terms = terms.split(" ");

    for (var term_index=0; term_index < splitted_terms.length; term_index++)
     {
        // don't highlight reserved catalog search terms
        var term = splitted_terms[term_index];
        var term_lower = term.toLowerCase();
        if (term_lower != 'not'
            && term_lower != 'and'
            && term_lower != 'or') {
            walkTextNodes(startnode, highlightTermInNode, term);
     }
    }
}

function highlightTermInNode(node, word) {
    var contents = node.nodeValue;
    var index = contents.toLowerCase().indexOf(word.toLowerCase());
    if (index < 0){return false};

    var parent = node.parentNode;
    if (parent.className != "highlightedSearchTerm") {
        // make 3 shiny new nodes
        var hiword = document.createElement("span");
        hiword.className = "highlightedSearchTerm";
        hiword.style.cssText = 'background:#FFFF8C;color:#999999;';
        hiword.appendChild(document.createTextNode(contents.substr(index, word.length)));
        parent.insertBefore(document.createTextNode(contents.substr(0, index)), node);
        parent.insertBefore(hiword, node);
        parent.insertBefore(document.createTextNode(contents.substr(index+word.length)), node);
        parent.removeChild(node);
    }
}

function walkTextNodes(node, func, data) {
    // traverse childnodes and call func when a textnode is found
    if (!node){return false}
    if (node.hasChildNodes) {
        // we can't use for (i in childNodes) here, because the number of
        // childNodes might change (higlightsearchterms)
        for (var i=0;i<node.childNodes.length;i++) {
            walkTextNodes(node.childNodes[i], func, data);
        }
        if (node.nodeType == 3) {
            // this is a text node
            func(node, data);
        }
    }
};
