syn region texZone start="\\begin{output}" end="\\end{output}\|%stopzone\>"
syn region texZone start="\\begin{outputsmall}" end="\\end{outputsmall}\|%stopzone\>"
syn region texZone start="\\begin{.\+code}" end="\\end{.\+code}\|%stopzone\>"
syn region texZone start="\\pyic\*\=\z([^\ta-zA-Z]\)" end="\z1\|%stopzone\>"
