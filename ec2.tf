resource "aws_instance" "k8s_master" {
  ami                         = "ami-042e8287309f5df03"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_mgr_policy.name

  tags = {
    Name      = "k8s master"
    Defender  = "false"
    yor_trace = "d5dc64de-f608-429c-b3b1-9b86fde8d0df"
  }
}

resource "aws_instance" "k8s_worker_1" {
  ami                         = "ami-08d4ac5b634553e16"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]

  tags = {
    Name      = "k8s worker"
    Defender  = "false"
    yor_trace = "98cda432-d859-4421-a755-38a8edc916b6"
  }
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    # install Docker runtime
    sudo apt update -y
    sudo apt install ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install docker-ce docker-ce-cli containerd.io -y
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    # install Defender
    sudo apt install jq -y
    AUTH_DATA="$(printf '{ "username": "%s", "password": "%s" }' "${var.PCC_ACCESS_KEY_ID}" "${var.PCC_SECRET_ACCESS_KEY}")"
    TOKEN=$(curl -sSLk -d "$AUTH_DATA" -H 'content-type: application/json' "${var.PCC_URL}/api/v1/authenticate" | jq -r ' .token ')
    DOMAINNAME=`echo ${var.PCC_URL} | cut -d'/' -f3`
    curl -sSLk -H "authorization: Bearer $TOKEN" -X POST "${var.PCC_URL}/api/v1/scripts/defender.sh" | sudo bash -s -- -c $DOMAINNAME -d "none" -m
    # setup environments for Log4Shell demo
    docker network create dirty-net
    docker container run -itd --rm --name vul-app-1 --network dirty-net fefefe8888/l4s-demo-app:1.0
    docker container run -itd --rm --name vul-app-2 --network dirty-net fefefe8888/l4s-demo-app:1.0
    docker container run -itd --rm --name att-svr --network dirty-net fefefe8888/l4s-demo-svr:1.0
    docker container run -itd --rm --network dirty-net --name attacker fefefe8888/my-ubuntu:18.04
    # build collections
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"name":"Log4Shell demo - vul-app-1 - ${random_string.suffix.id}","containers":["vul-app-1"],"hosts":["*"],"images":["fefefe8888/l4s-demo-app:1.0"],"labels":["*"],"appIDs":["*"],"functions":["*"],"namespaces":["*"],"accountIDs":["*"],"codeRepos":["*"],"clusters":["*"]}' "${var.PCC_URL}/api/v1/collections"
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"name":"Log4Shell demo - vul-app-2 - ${random_string.suffix.id}","containers":["vul-app-2"],"hosts":["*"],"images":["fefefe8888/l4s-demo-app:1.0"],"labels":["*"],"appIDs":["*"],"functions":["*"],"namespaces":["*"],"accountIDs":["*"],"codeRepos":["*"],"clusters":["*"]}' "${var.PCC_URL}/api/v1/collections"
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"name":"Shell demo - attacker - ${random_string.suffix.id}","containers":["attacker"],"hosts":["*"],"images":["fefefe8888/my-ubuntu:18.04"],"labels":["*"],"appIDs":["*"],"functions":["*"],"namespaces":["*"],"accountIDs":["*"],"codeRepos":["*"],"clusters":["*"]}' "${var.PCC_URL}/api/v1/collections"
    # build runtime rules
    NEW_RULES='[{"name":"vul-app-2 - ${random_string.suffix.id}","previousName":"","collections":[{"name":"Log4Shell demo - vul-app-2 - ${random_string.suffix.id}"}],"advancedProtection":true,"processes":{"effect":"prevent","blacklist":[],"whitelist":[],"checkCryptoMiners":true,"checkLateralMovement":true,"checkParentChild":true,"checkSuidBinaries":true},"network":{"effect":"alert","blacklistIPs":[],"blacklistListeningPorts":[],"whitelistListeningPorts":[],"blacklistOutboundPorts":[],"whitelistOutboundPorts":[],"whitelistIPs":[],"skipModifiedProc":false,"detectPortScan":true,"skipRawSockets":false},"dns":{"effect":"prevent","blacklist":[],"whitelist":[]},"filesystem":{"effect":"prevent","blacklist":[],"whitelist":[],"checkNewFiles":true,"backdoorFiles":true,"skipEncryptedBinaries":false,"suspiciousELFHeaders":true},"kubernetesEnforcement":true,"cloudMetadataEnforcement":true,"wildFireAnalysis":"alert"},{"name":"vul-app-1 - ${random_string.suffix.id}","previousName":"","collections":[{"name":"Log4Shell demo - vul-app-1 - ${random_string.suffix.id}"}],"advancedProtection":true,"processes":{"effect":"alert","blacklist":[],"whitelist":[],"checkCryptoMiners":true,"checkLateralMovement":true,"checkParentChild":true,"checkSuidBinaries":true},"network":{"effect":"alert","blacklistIPs":[],"blacklistListeningPorts":[],"whitelistListeningPorts":[],"blacklistOutboundPorts":[],"whitelistOutboundPorts":[],"whitelistIPs":[],"skipModifiedProc":false,"detectPortScan":true,"skipRawSockets":false},"dns":{"effect":"alert","blacklist":[],"whitelist":[]},"filesystem":{"effect":"alert","blacklist":[],"whitelist":[],"checkNewFiles":true,"backdoorFiles":true,"skipEncryptedBinaries":false,"suspiciousELFHeaders":true},"kubernetesEnforcement":true,"cloudMetadataEnforcement":true,"wildFireAnalysis":"alert"},{ "name":"Shell - attacker-1 - ${random_string.suffix.id}", "previousName":"", "collections":[{"name":"Shell demo - attacker - ${random_string.suffix.id}"}], "advancedProtection":true, "processes":{"effect":"alert","blacklist":[],"whitelist":[],"checkCryptoMiners":true,"checkLateralMovement":true,"checkParentChild":true,"checkSuidBinaries":true}, "network":{"effect":"alert","blacklistIPs":[],"blacklistListeningPorts":[],"whitelistListeningPorts":[],"blacklistOutboundPorts":[],"whitelistOutboundPorts":[],"whitelistIPs":[],"skipModifiedProc":false,"detectPortScan":true,"skipRawSockets":false}, "dns":{"effect":"alert","blacklist":[],"whitelist":["*.paloaltonetworks.com"]}, "filesystem":{"effect":"alert","blacklist":[],"whitelist":[],"checkNewFiles":true,"backdoorFiles":true,"skipEncryptedBinaries":false,"suspiciousELFHeaders":true}, "kubernetesEnforcement":true,"cloudMetadataEnforcement":true,"wildFireAnalysis":"alert" }]'
    ALL_RULES=$(curl -k -X GET -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/policies/runtime/container" | jq --argjson nr "$NEW_RULES" ' .rules = $nr + .rules ')
    curl -k -X PUT -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/policies/runtime/container" -d "$ALL_RULES"
    # add WaaS rules
    NEW_RULES='[{"name":"vul-app-2 - ${random_string.suffix.id}","collections":[{"name":"Log4Shell demo - vul-app-2 - ${random_string.suffix.id}"}],"applicationsSpec":[{"appID":"app-0001","sessionCookieSameSite":"Lax","customBlockResponse":{},"banDurationMinutes":5,"certificate":{"encrypted":""},"tlsConfig":{"minTLSVersion":"1.2","metadata":{"notAfter":"0001-01-01T00:00:00Z","issuerName":"","subjectName":""},"HSTSConfig":{"enabled":false,"maxAgeSeconds":31536000,"includeSubdomains":false,"preload":false}},"dosConfig":{"enabled":false,"alert":{},"ban":{}},"apiSpec":{"endpoints":[{"host":"*","basePath":"*","exposedPort":0,"internalPort":8080,"tls":false,"http2":false}],"effect":"disable","fallbackEffect":"disable","skipLearning":false},"botProtectionSpec":{"userDefinedBots":[],"knownBotProtectionsSpec":{"searchEngineCrawlers":"disable","businessAnalytics":"disable","educational":"disable","news":"disable","financial":"disable","contentFeedClients":"disable","archiving":"disable","careerSearch":"disable","mediaSearch":"disable"},"unknownBotProtectionSpec":{"generic":"disable","webAutomationTools":"disable","webScrapers":"disable","apiLibraries":"disable","httpLibraries":"disable","botImpersonation":"disable","browserImpersonation":"disable","requestAnomalies":{"threshold":9,"effect":"disable"}},"sessionValidation":"disable","interstitialPage":false,"jsInjectionSpec":{"enabled":false,"timeoutEffect":"disable"},"reCAPTCHASpec":{"enabled":false,"siteKey":"","secretKey":{"encrypted":""},"type":"checkbox","allSessions":true,"successExpirationHours":24}},"networkControls":{"advancedProtectionEffect":"alert","subnets":{"enabled":false,"allowMode":true,"fallbackEffect":"alert"},"countries":{"enabled":false,"allowMode":true,"fallbackEffect":"alert"}},"body":{"inspectionSizeBytes":131072},"intelGathering":{"infoLeakageEffect":"alert","removeFingerprintsEnabled":true},"maliciousUpload":{"effect":"disable","allowedFileTypes":[],"allowedExtensions":[]},"csrfEnabled":true,"clickjackingEnabled":true,"sqli":{"effect":"alert","exceptionFields":[]},"xss":{"effect":"alert","exceptionFields":[]},"attackTools":{"effect":"alert","exceptionFields":[]},"shellshock":{"effect":"alert","exceptionFields":[]},"malformedReq":{"effect":"alert","exceptionFields":[]},"cmdi":{"effect":"alert","exceptionFields":[]},"lfi":{"effect":"alert","exceptionFields":[]},"codeInjection":{"effect":"alert","exceptionFields":[]},"remoteHostForwarding":{},"customRules":[{"_id":35,"action":"audit","effect":"prevent"},{"_id":36,"action":"audit","effect":"prevent"}]}]}]'
    ALL_RULES=$(curl -k -X GET -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/policies/firewall/app/container" | jq --argjson nr "$NEW_RULES" ' .rules = $nr + .rules ')
    curl -k -X PUT -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/policies/firewall/app/container" -d "$ALL_RULES"
    # get container model id and force activate
    PROFILE_ID=$(curl -k -X GET -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/profiles/container" | jq -r ' .[] | select(.image == "fefefe8888/l4s-demo-app:1.0") | ._id ')
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualLearning"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualActive"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    PROFILE_ID=$(curl -k -X GET -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/profiles/container" | jq -r ' .[] | select(.image == "fefefe8888/l4s-demo-svr:1.0") | ._id ')
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualLearning"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualActive"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    PROFILE_ID=$(curl -k -X GET -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/profiles/container" | jq -r ' .[] | select(.image == "fefefe8888/my-ubuntu:18.04") | ._id ')
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualLearning"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    curl -k -X POST -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"state": "manualActive"}' "${var.PCC_URL}/api/v1/profiles/container/$PROFILE_ID/learn"
    # enable WildFire
    curl -k -X PUT -H "authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${var.PCC_URL}/api/v1/settings/wildfire" -d '{"region":"sg","runtimeEnabled":true,"complianceEnabled":true,"uploadEnabled":true,"graywareAsMalware":false}'
    EOF

  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

