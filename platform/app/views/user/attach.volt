{{ stylesheet_link("assets/bower/xterm.js/src/xterm.css") }}
{{ stylesheet_link("css/xterm.css") }}
{{ stylesheet_link("assets/bower/bootstrap/dist/css/bootstrap.min.css") }}
{{ stylesheet_link("assets/bower/xterm.js/addons/fullscreen/fullscreen.css") }}
{{ javascript_include("js/fetch.min.js") }}
{{ javascript_include("assets/bower/xterm.js/src/xterm.js") }}
{{ javascript_include("assets/bower/xterm.js/addons/attach/attach.js") }}
{{ javascript_include("assets/bower/xterm.js/addons/fit/fit.js") }}
{{ javascript_include("assets/bower/xterm.js/addons/fullscreen/fullscreen.js") }}
</head>
<body>
<div class="container-fluid">
    <div class="col-md-6 full-height">
        <div class="container-fluid scrollable">
            {% if report %}
            {{ report }}
            {% endif %}
        </div>
    </div>
    <div class="col-md-6">
        <div id="terminal-container"></div>
    </div>
</div>
<div>
    <h2>Options</h2>
    <label><input type="checkbox" id="option-cursor-blink">cursorBlink</label>
</div>
<script>
    var term,
            protocol,
            socketURL,
            socket,
            pid,
            charWidth,
            charHeight;

    var terminalContainer = document.getElementById('terminal-container'),
            optionElements = {
                cursorBlink: document.querySelector('#option-cursor-blink')
            };
    // colsElement = document.getElementById('cols'),
    // rowsElement = document.getElementById('rows');

    function setTerminalSize() {
        var cols = parseInt(colsElement.value),
                rows = parseInt(rowsElement.value),
                width = (cols * charWidth).toString() + 'px',
                height = (rows * charHeight).toString() + 'px';

        terminalContainer.style.width = width;
        terminalContainer.style.height = height;
        term.resize(120, 30);
    }

    // colsElement.addEventListener('change', setTerminalSize);
    // rowsElement.addEventListener('change', setTerminalSize);

    optionElements.cursorBlink.addEventListener('change', createTerminal);

    createTerminal();

    function createTerminal() {
        // Clean terminal
        while (terminalContainer.children.length) {
            terminalContainer.removeChild(terminalContainer.children[0]);
        }
        term = new Terminal({
            cursorBlink: optionElements.cursorBlink.checked
        });
        term.on('resize', function (size) {
            if (!pid) {
                return;
            }
            var cols = size.cols,
                    rows = size.rows,
                    url = '/terminals/' + pid + '/size?cols=' + cols + '&rows=' + rows;

            fetch(url, {method: 'POST'});
        });
        protocol = (location.protocol === 'https:') ? 'wss://' : 'ws://';
        socketURL = protocol + location.hostname + ((location.port) ? (':' + location.port) : '') + '/terminals/';

        term.open(terminalContainer);
        term.fit();

        var initialGeometry = term.proposeGeometry(),
                cols = initialGeometry.cols,
                rows = initialGeometry.rows;

   //     fetch('/terminals?cols=' + cols + '&rows=' + rows, {method: 'POST'}).then(function (res) {

            charWidth = Math.ceil(term.element.offsetWidth / cols);
            charHeight = Math.ceil(term.element.offsetHeight / rows);

     //       res.text().then(function (pid) {
                window.pid = pid;
                socketURL += pid;
                socket = new WebSocket("{{ url }}");
                socket.onopen = runRealTerminal;
                socket.onclose = runFakeTerminal;
                socket.onerror = runFakeTerminal;
       //     });
       // });
    }


    function runRealTerminal() {
        term.attach(socket);
        term._initialized = true;
    }

    function runFakeTerminal() {
        if (term._initialized) {
            return;
        }

        term._initialized = true;

        var shellprompt = '$ ';

        term.prompt = function () {
            term.write('\r\n' + shellprompt);
        };

        term.writeln('Welcome to xterm.js');
        term.writeln('This is a local terminal emulation, without a real terminal in the back-end.');
        term.writeln('Type some keys and commands to play around.');
        term.writeln('');
        term.prompt();

        term.on('key', function (key, ev) {
            var printable = (
                    !ev.altKey && !ev.altGraphKey && !ev.ctrlKey && !ev.metaKey
            );

            if (ev.keyCode == 13) {
                term.prompt();
            } else if (ev.keyCode == 8) {
                // Do not delete the prompt
                if (term.x > 2) {
                    term.write('\b \b');
                }
            } else if (printable) {
                term.write(key);
            }
        });

        term.on('paste', function (data, ev) {
            term.write(data);
        });
    }

</script>
<!--{{ javascript_include("js/xterm.js") }}-->
</body>
