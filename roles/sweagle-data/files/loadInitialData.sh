#!/bin/bash
echo start loading tenant data

if [ "$#" -lt "1" ]; then
   read -p "Enter the tenant Name to load : " tenantName
else
   tenantName="$1"
fi

if [ "$2" ]; then
  force_local_installation=$2
else
  force_local_installation=false
fi

if [ "$3" ]; then
  sweagleURL="http://$3"
else
  sweagleURL="http://localhost"
fi

scriptDir=$(dirname "$0")
sweagleUser="admin_$tenantName"
sweaglePwd="testtest"
sweagleAuth="Basic c3dlYWdsZS1jbGllbnQ6c3dlYWdsZVNlY3JldA=="
sweagleExpertGit="https://github.com/sweagleExpert"

function getAuthenticationToken()
{
  response=$(curl -X POST "$sweagleURL/oauth/token?grant_type=password&username=$sweagleUser&password=$sweaglePwd" -H "Authorization: $sweagleAuth")
  token=$(echo $response | sed "s/{.*\"access_token\":\"\([^\"]*\).*}/\1/g")
  echo $token
}

function createChangeset()
{
  echo 'Creating Changeset'
  response=$(curl -s -X POST -H "Authorization: bearer $token" -H "Accept: application/vnd.siren+json" "$sweagleURL/api/v1/data/changeset" -d "title=New+Changeset&description=BashChangeSet")

  csId=$(echo $response | sed "s/{.*\"id\":\([^,]*\).*}/\1/g")
}

function approveChangeset()
{
  echo "Approving changeset $csId"

  approve=$(curl -s -X POST -H "Authorization: bearer $token" -H "Accept: application/vnd.siren+json" "$sweagleURL/api/v1/data/changeset/$csId/approve")
}

function createTypeChangeset()
{
  echo "== creating Type ChangeSet =="
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/changeset" -H "Accept: application/vnd.siren+json" -d "title=initial+create+$NOW&description=inital+data+upload")

  tsId=$(echo $response | sed "s/{.*\"id\":\([^,]*\).*}/\1/g")
  echo "Type Changeset $tsId created"
}

function approveTypeChangeset()
{
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/changeset/$tsId/approve" -H "Accept: application/vnd.siren+json")
  echo "Approved Type Changeset $tsId"
}

function createParsers()
{
  echo "== creating default parsers =="

  parsers=("validator" "exporter" "template")

  for type in "${parsers[@]}"; do
    if [ "$force_local_installation" = false ]; then
      echo "= connecting to Git ${sweagleExpertGit}/${type}s"
      git clone "${sweagleExpertGit}/${type}s" "$scriptDir/${type}s"
    fi
    for parser in $scriptDir/${type}s/*.js; do
      name=$(basename $parser|sed 's/\.js//')
      description=$(grep -i "description:" $parser|sed -E 's/^\s*[\/*]+\s*description:\s*//I')
      if [ -z "$description" ]; then
        description=$name
      fi

      # Create exporter
      echo "Creating $type $name"
      if [ "$argParserType" = "template" ]; then
        response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/tenant/template-parser" -H "Accept: application/vnd.siren+json" -d "name=$name&description=$description")
        exId=$(echo $response| sed "s/{.*\"id\":\([^,]*\).*}/\1/g")
        # Dump content in parser
        content=$(cat $parser)
        response=$(curl -s -X POST -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/vnd.siren+json" "$sweagleURL/api/v1/tenant/template-parser/$exId" --data-urlencode "template=$content")
        # Publish parser
        response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/tenant/template-parser/$exId/publish" -H "Accept: application/vnd.siren+json")
        # Make parser default
        #response=$(curl -s -X POST -H "Authorization: bearer $token" "$sweagleURL/api/v1/tenant/template-parser/$exId/default")
      else
        response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/tenant/metadata-parser" -H "Accept: application/vnd.siren+json" -d "name=$name&description=$description&parserType=$(echo $type|tr a-z A-Z)")
        exId=$(echo $response| sed "s/{.*\"id\":\([^,]*\).*}/\1/g")
        # Dump content in parser
        content=$(cat $parser)
        response=$(curl -s -X POST -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/vnd.siren+json" "$sweagleURL/api/v1/tenant/metadata-parser/$exId" --data-urlencode "scriptDraft=$content")
        # Publish parser
        response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/tenant/metadata-parser/$exId/publish" -H "Accept: application/vnd.siren+json")
        # Make parser default for selected ones
        if [ "$name" = "all" ] || [ "$name" = "returnDataForNode" ] || [ "$name" = "returnDataForPath" ]; then
          response=$(curl -s -X POST -H "Authorization: bearer $token" "$sweagleURL/api/v1/tenant/metadata-parser/$exId/default")
        fi
      fi
    done
    #rm -rf ./${type}s
  done
}

function createTags()
{
  echo "== loading default tags =="

  tags=("technical" "feature flag" "credential" "business")
  tagDescriptions=("identifies a technical setting" "defines a feature toggle setting" "defines a sensitive MDI such as username, password or API key" "Defines a business related setting")
  i=0

  for tag in "${tags[@]}"
  do
    response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/tag" -H "Accept: application/vnd.siren+json" -d "name=$tag&description=${tagDescriptions[$i]}")
    ((i++))
  done
}

function createMdiTypes()
{
  createTypeChangeset
  echo "Changeset Id: $tsId"

  if [ "$force_local_installation" = false ]; then
    git clone "${sweagleExpertGit}/mditypes"
  fi

  for mdiType in ./mditypes/*.props; do
    source $mdiType

    if [ -z "$name" ] || [ -z "$description" ] || [ -z "$isRequired" ] || [ -z "$isSensitive" ] || [ -z "$type" ] || [ -z ${regex} ]; then
      echo "Not all required variables are set, skipping creation of mdiType ${mdiType}"
      continue
    fi

    response=$(curl -X POST "$sweagleURL/api/v1/model/mdiType?changeset=$tsId"  -H "Authorization: bearer $token" -H "Accept: application/vnd.siren+json" --data-urlencode "name=${name}" --data-urlencode "required=${isRequired}" --data-urlencode "description=${description}" --data-urlencode "sensitive=${isSenstitive}" --data-urlencode "valueType=${type}" --data-urlencode "regex=${regex}")
    echo $response

    unset name description isRequired isSensitive type regex
  done

  approveTypeChangeset
}

function createTypes()
{
  createTypeChangeset
  echo "Using Type Changeset $tsId"


  echo "== creating general node type =="
  response=$(curl -s -X POST -H "authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=generalNode&description=General+node&internal=true&inheritFromParent=false")
  genNodeID=$(echo $response| sed "s/{.*\"id\":\([^,]*\).*}/\1/g")

  echo $genNodeID

  echo ".. creating nodeType"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=environmentInstance&description=Environment+instance&inheritFromParent=false")
  nodeID=$(echo $response| sed "s/{.*\"id\":\([^,]*\).*}/\1/g")

  echo "== creating nodeType attributes =="
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=env.name&description=name+of+the+environment&required=true&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=env.active&description=is+environment+active+or+not&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=infra&description=assigned+infrastructure+components&required=false&referenceType=$genNodeID")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=currentDeployed&description=current+deployed+application+components&required=false&referenceType=$genNodeID")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=assignedRelease&description=current+assigned+release&required=false&referenceType=$genNodeID")
  echo "attributes created $response\n"


  echo "== creating type environment Category =="
  echo ".. creating nodeType"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=environmentCategory&description=Environment+category&inheritFromParent=false")
  echo $response
  nodeID=$(echo "$response" |sed "s/{.*\"id\":\([^,]*\).*}/\1/g" )
  echo -e "node ID received:  $nodeID\n"

  echo ".. creating attributes"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=settings.LoadBalancedEnabled&description=is+environment+load+balanced&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=settings.dynamicScaling&description=is+environment+setup+for+dynamic+scaling&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=SLA.availability.MSDT&description=maximum+single+downtime+in+minutes&required=false&valueType=Integer")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=SLA.availability.pct&description=percentage+time+available+during+window&required=false&valueType=Decimal")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=SLA.availability.window&description=time+window+for+SLA&required=false&valueType=Regex&regex=^(24x7|24x5|8x5)$")
  echo "attributes created $response\n"


  echo "== creating type application Component"
  echo ".. creating nodeType"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=appComponent&description=Application+component&inheritFromParent=false")
  echo $response
  nodeID=$(echo "$response"| sed "s/{.*\"id\":\([^,]*\).*}/\1/g")
  echo -e "node ID received:  $nodeID\n"

  echo ".. creating attributes"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=EOL.announced&description=EndofLife+announced+already&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=EOL.date&description=announced+date+for+EndofLife&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=component.name&description=name+of+the+component&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=artifact.buildName&description=name+of+the+artifact&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=component.owner.team&description=name+of+the+team&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=component.owner.contact&description=team+email+adres&required=false&valueType=Regex&regex=^[a-zA-Z0-9._%+-]*\@[a-zA-Z0-9.-]*.[a-zA-Z]*$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=versions&description=component+versions&required=false&referenceType=$genNodeID")



  echo "== creating type application Component version"
  echo ".. creating nodeType"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=componentVersion&description=Component+version&internal=true&inheritFromParent=false")
  echo $response
  nodeID=$(echo "$response" | sed "s/{.*\"id\":\([^,]*\).*}/\1/g" )
  echo -e "node ID received:  $nodeID\n"

  echo ".. creating attributes"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=version.nbr&description=version+label&required=true&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=version.latestBuild&description=version+build+number&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=artifact.url&description=url+to+the+artifact&required=false&valueType=Text")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=versionPassport&description=test+attestations&required=false&referenceType=$genNodeID")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=versionDeployHistory&description=deployment+history&required=false&referenceType=$genNodeID")
  echo "attributes created $response\n"

  echo "== creating type application"

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=application&description=Application&inheritFromParent=false")
  nodeID=$(echo "$response"| sed "s/{.*\"id\":\([^,]*\).*}/\1/g" )

  echo "== creating attributes"

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=type&description=Application+type&required=true&valueType=Text")

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=team&description=Team+name+responsible+for+the+application&required=true&valueType=Text")

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=team_email&description=Email+of+responsible+team&required=true&valueType=Text")

  echo "== creating type server"

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/type" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&name=server&description=Server+instance&inheritFromParent=false")
  echo $response
  nodeID=$(echo "$response"| sed "s/{.*\"id\":\([^,]*\).*}/\1/g" )
  echo -e "node ID received:  $nodeID\n"
  echo "new line"

  echo ".. creating attributes"
  response=$(curl -s -X POST -H "Authorization: bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=serverRole&description=Role+of+the+server&required=true&valueType=Regex&regex=^(all-in-one|ui|core)$")
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=IP.internal&description=internal+ip+address&required=true&valueType=Text")
  echo "curl -s -X POST -H 'authorization: Bearer '$aToken $sweagleURL'/api/v1/model/attribute' -H 'Accept: application/vnd.siren+json' -d 'changeset='$tsId'&type='$nodeID'&name=IP.internal&description=internal+ip+address&required=true&valueType=Text'"
  echo "attributes created $response\n"

  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=IP.external&description=external+ip+address&required=false&valueType=Text")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=setting.FQDN&description=full+qualified+domain+name&required=false&valueType=Text")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=setting.network&description=network+zone&required=false&valueType=Text")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=setting.regionalZone&description=geographical+location+of+server&required=false&valueType=Text")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=firewall.status&description=is+firewall+enabled+or+disabled&required=true&valueType=Regex&regex=^(enabled|disabled)$")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=firewall.HTTPenabled&description=is+firewall+enabled+for+http+traffic&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  echo "attributes created $response\n"
  response=$(curl -s -X POST -H "Authorization: Bearer $token" "$sweagleURL/api/v1/model/attribute" -H "Accept: application/vnd.siren+json" -d "changeset=$tsId&type=$nodeID&name=firewall.HTTPSenabled&description=is+firewall+enabled+for+https+traffic&required=true&valueType=Regex&regex=^([tT][rR][uU][eE]|[fF][aA][lL][sS][eE])$")
  echo "attributes created $response\n"

  approveTypeChangeset
}

function createTypedNodes()
{
  echo "== loading default data model =="

  if [ -f "$scriptDir/data/data.json" ]; then
    echo "File 'data.json' exists"
  else
    echo "File does not exist.  Please add a json file 'data.json' with the data structure to upload in the same folder where this script is run from."
    exit 1
  fi


  createChangeset

  response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=sample&changeset=$csId" -H "Authorization: bearer $token")
  sampleNodeId=$(echo $response|jq '.id')

  if [[ -z $sampleNodeId ]] || [[ $sampleNodeId == "null" ]]; then
    exit 1
  fi
  echo "sampleNodeId = $sampleNodeId"

  ######################################
  # Creating environment related nodes #
  ######################################

  echo "Creating 'environments' root node"
  response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=environments&changeset=$csId&parentNode=$sampleNodeId" -H "Authorization: bearer $token")

  echo $response
  envNode=$(echo $response|jq .id)

  environments=$(cat $scriptDir/data/data.json|jq '.environments|to_entries[].key'|sed 's/\"//g')
  envNames=()
  envIds=()

  for e in $environments; do
    echo "Creating environment category $e"
    response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=$e&typeName=environmentCategory&changeset=$csId&parentNode=$envNode" -H "Authorization: bearer $token")
    parentNode=$(echo $response|jq .id)
    subenvs=$(cat $scriptDir/data/data.json|jq ".environments.$e|to_entries[].key"|sed 's/\"//g')

    for s in $subenvs; do
      if [[ ${#s} -gt 4 ]]; then
        continue
      fi
      echo "Creating environment instance $s"
      response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=$s&typeName=environmentInstance&parentNode=$parentNode&changeset=$csId" -H "Authorization: bearer $token")
      nodeId=$(echo $response|jq .id)
      envNames=("${envNames[@]}" "$s")
      envIds=("${envIds[@]}" "$nodeId")
      #createMetadataset $nodeId $s
    done
  done

  ####################################
  # Creating component related nodes #
  ####################################

  compNames=()
  compIds=()

  echo "Creating 'components' root node"
  response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=components&changeset=$csId&parentNode=$sampleNodeId" -H "Authorization: bearer $token")
  compNode=$(echo $response|jq .id)

  components=$(cat $scriptDir/data/data.json|jq '.components|to_entries[].key'|sed 's/\"//g')

  for c in $components; do
    echo "Creating component $c"

    response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=$c&parentNode=$compNode&typeName=appComponent&changeset=$csId" -H "Authorization: bearer $token")

    compId=$(echo $response|jq .id)
    compNames=("${compNames[@]}" "$c")
    compIds=("${compIds[@]}" "${compId}")
  done

  #########################
  # Creating server nodes #
  #########################

  response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=servers&changeset=$csId&parentNode=$sampleNodeId" -H "Authorization: bearer $token")
  serverNode=$(echo $response| jq .id)

  echo "serverNode Id: $serverNode"

  servers=$(cat $scriptDir/data/data.json|jq '.servers|to_entries[].key'|sed 's/\"//g')

  for server in $servers; do
    echo "Creating server $server"
    response=$(curl -s -X POST "$sweagleURL/api/v1/data/node?name=$server&parentNode=$serverNode&typeName=server&changeset=$csId" -H "Authorization: bearer $token")
  done

  approveChangeset
}

function createDataModel
{
  createChangeset

  echo "Creating Data Model"

  response=$(curl -s -X POST "$sweagleURL/api/v1/data/bulk-operations/dataLoader/upload?nodePath=sample&format=json&autoApprove=true" -H "Authorization: bearer $token" -H "Content-Type: application/json" -d "@$scriptDir/data/data.json")

  approveChangeset
}


function createIncludes()
{
  createChangeset

  servers=$(cat $scriptDir/data/data.json|jq '.servers|to_entries[].key'|sed 's/\"//g')

  echo "Starting server includes"

  for server in $servers; do
    envCat=${server:0:3}
    envInst=${server:0:4}

    echo "Including $server into $envCat => $envInst"

    response=$(curl -s -X POST "$sweagleURL/api/v1/data/include/byPath?changeset=$csId&parentNode=sample,environments,$envCat,$envInst,infra&referenceNode=sample,servers,$server" -H "Authorization: bearer $token")
  done

  approveChangeset
}

function applyInheritance
{
  createChangeset
  echo "Applying inheritance"

  for comp in "${compNames[@]}"; do
    echo "Applying inheritance on sample,components,$comp,versions"
    response=$(curl -s -X POST "$sweagleURL/api/v1/data/node/inherit-by-path?changeset=$csId&path=sample,components,$comp,versions" -H "Authorization: bearer $token")

    echo $response
  done

  for env in "${envNames[@]}"; do
    category=${env:0:3}
    echo "Applying inheritance in sample,environments,$category,$env"
    response=$(curl -s -X POST "$sweagleURL/api/v1/data/node/inherit-by-path?changeset=$csId&path=sample,environments,$category,$env" -H "Authorization: bearer $token")

    echo $response
  done

  approveChangeset
}

function applyTags
{
  echo "Applying tags"

  response=$(curl -s -X POST "$sweagleURL/api/v1/data/bulk-operations/tag?tag=technical&approve=true&sensitive=false" -H "Authorization: bearer $token" -H "Content-Type: application/json" -d '{"keyRegex": "(component)"}')

  response=$(curl -s -X POST "$sweagleURL/api/v1/data/bulk-operations/tag?tag=credential&approve=true&sensitive=false" -H "Authorization: bearer $token" -H "Content-Type: application/json" -d '{"keyRegex": "(password)"}')

}

function createMetadatasets
{
  metadatasets=()
  createChangeset

  echo "Creating metadatasets"
  i=0

  for env in "${envNames[@]}"; do
    echo "Creating metadataset for $env"
    envId=${envIds[$i]}
    echo "ENV ID: $envId"
    response=$(curl -s -X POST "$sweagleURL/api/v1/data/include?changeset=$csId&name=sample.$env&referenceNode=$envId" -H "Authorization: bearer $token" -H "Content-Type: application/vnd.siren+json;charset=UTF-8")

    echo $response
    mdsId=$(echo $response|jq '.master.id' --raw-output)
    metadatasets=("${metadatasets[@]}" "$mdsId")
    ((i++))
  done

  i=0

  echo "Creating 'sample.components' metadataset"
  response=$(curl -s -X POST "$sweagleURL/api/v1/data/include?changeset=$csId&name=sample.components&referenceNode=$compNode" -H "Authorization: bearer $token" -H "Content-Type: application/vnd.siren+json;charset=UTF-8")
  echo $response
  mdsId=$(echo $response|jq '.master.id' --raw-output)
  metadatasets=("${metadatasets[@]}" "$mdsId")

  approveChangeset
}

function setPreferences
{
  echo "Updating preferences"

  response=$(curl -s -X POST "$sweagleURL/api/tenant/preferences" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: bearer $token" -d 'validation_report.types.metadata_invalid.level=off')

  echo $response
}

function createWorkspace
{
   echo "Creating Sample Application Workspace"
   response=$(curl -s -X POST "$sweagleURL/api/v1/tenant/workspace?name=sample&description=sample+application+workspace" -H "Authorization: bearer $token" -H "Content-Type: application/vnd.siren+json;charset=UTF-8")

  echo $response

  tree=$(curl -s -X GET "$sweagleURL/api/v1/data/node/static-tree" -H "Authorization: bearer $token")
  dimension=$(echo $tree|jq '.dimensions[]|select(.version.name == "sample").id')
  echo "Dimension ID: $dimension"

  workspaceId=$(echo $response|jq '._entities[0].id')
  echo "Workspace ID: $workspaceId"

  echo "Linking workspace to sample dimension"
  response=$(curl -s -X POST "$sweagleURL/api/v1/tenant/workspace/$workspaceId/dimensions" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "dimension=$dimension")

  echo $response

  echo "Linking workspace to metadatasets"

  for mds in "${metadatasets[@]}"; do
    response=$(curl -s -X POST "$sweagleURL/api/v1/tenant/workspace/$workspaceId/metadatasets" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "metadataset=$mds")

    echo $response
  done
}

function createRolesAndPolicies
{
  echo "Creating 'Security manager' role"
  roleCreation=$(curl -s -X POST "$sweagleURL/api/v1/tenant/role" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "name=Security+manager&description=Can+view+and+edit+credential+settings")
  roleId=$(echo $roleCreation|jq -r '.id')

  tags=$(curl -s -X GET "$sweagleURL/api/v1/model/tag" -H "Authorization: bearer $token")
  credentialTag=$(echo $tags|jq '._entities[]|select(.name == "credential").id')
  policyCreation=$(curl -s -X POST "$sweagleURL/api/v1/tenant/policy" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "name=Credential+editor&description=Allows+to+edit+credential+settings&type=DataTagAccess&canEdit=true&tag=$credentialTag")
  policyId=$(echo $policyCreation|jq -r '.id')

  echo "Assigning policy to role"
  response=$(curl -s -X POST "$sweagleURL/api/v1/tenant/role/$roleId/policies" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "policies=$policyId")

  echo "Creating view only credential tag policy"
  policyCreation=$(curl -s -X POST "$sweagleURL/api/v1/tenant/policy" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "name=Credential+viewer&description=Allows+to+view+credential+settings&type=DataTagAccess&canEdit=false&tag=$credentialTag")
  policyId=$(echo $policyCreation|jq -r '.id')

  roleCreation=$(curl -s -X POST "$sweagleURL/api/v1/tenant/role" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "name=Security+reviewer&description=Can+view+credential+settings")
  roleId=$(echo $roleCreation|jq -r '.id')

  echo "Assigning policy to role"
  response=$(curl -s -X POST "$sweagleURL/api/v1/tenant/role/$roleId/policies" -H "Authorization: bearer $token" -H "Content-Type: application/x-www-form-urlencoded" -d "policies=$policyId")
}

getAuthenticationToken
setPreferences
createRolesAndPolicies
createParsers
createTags
createMdiTypes
createTypes
createTypedNodes
createDataModel
createIncludes
applyTags
createMetadatasets
createWorkspace
applyInheritance
