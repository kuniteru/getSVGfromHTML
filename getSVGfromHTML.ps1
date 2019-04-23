Param (
    [parameter(mandatory=$true)][String]$uri,
    [String]$OutputDir = "."
)

$response = Invoke-WebRequest -Uri $uri

$defines = @{}
$svgs = $response.AllElements.Where{$_.tagName -eq "svg"}

foreach ($svg in $svgs) {
    $defs = ([xml]$svg.outerHTML).svg.defs
    foreach ($def in $defs) {
        foreach ($childNode in $def.ChildNodes) {
            $defines.Add($childNode.attributes["id"].Value, $childNode)
        }
    }
}

$i = 1
foreach ($svg in $svgs) {
    $svgDoc = [xml]$svg.outerHTML
    $ns = New-Object Xml.XmlNamespaceManager $svgDoc.NameTable
    $ns.AddNamespace("svg", "http://www.w3.org/2000/svg") 
    $svg = $svgDoc.SelectNodes("/svg:svg[not(svg:defs)]", $ns)

    if ($svg.Count -gt 0) {
        $uses = $svg.SelectNodes("svg:use", $ns)
        $defs = ""
        foreach ($use in $uses) {
            $xlink = $use.GetAttribute("xlink:href") -replace "^#", ""
            $def = $svgDoc.SelectNodes("/svg:svg/svg:defs/svg:symbol[@id='" + $xlink +"']", $ns)
            $defs = $defs + "+ " + $xlink
            if ($def.count -eq 0) {
                $def = $svgDoc.ImportNode($defines[$xlink], $true)
                $svgDoc["svg"].AppendChild($def)
            }
        }

        $fileName = $svg.getAttribute("id")
        if ($id.Length -eq 0) {
            $fileName = $svg.getAttribute("name")
            if ($id.Length -eq 0) {
                if ($defs.Length -gt 0) {
                    $fileName = $defs.remove(0, 2) + "_" + [string]$i
                } else {
                    $fileName = [string]$i
                }
                $i ++
            }
        }

        $filePath = $OutputDir + '\' + $fileName + ".svg"
        Out-File -FilePath $filePath -Encoding utf8 -InputObject $svgDoc.OuterXml
    }
}
