# Instalação e configuração do Argo CD no K3s

## Instalação padrão

```bash
k create namespace argocd

k config set-context --current --namespace=argocd 

k apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

ARGO_PWD=`k -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

k port-forward svc/argocd-server -n argocd 1443:443
```

## Certificados

### CA 

```bash
mkdir ca && cd ca

openssl genrsa -des3 -out ArgoCDRootCA.key.pem 4096

openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out ArgoCDRootCA.crt.pem
```

### Servidor

```bash
mkdir server && cd server

lvim argocd-server.argocd.sh

chmod +x argocd-server.argocd.sh

./argocd-server-argocd.sh

openssl req -in argocd-server.argocd.csr -text

```

### Verificar os certificados

```bash
openssl verify -CAfile ArgoCDRootCA.crt.pem argocd-server.argocd.crt.pem

openssl x509 -in argocd-server.argocd.crt.pem -text

```


### Substituir Certificado

O certificado gerado é auto assinado, para que seja possível exibir como seguro no chrome,
será necessário gerar uma CA para assinar o novo certificado.

```bash
k config set-context --current --namespace=argocd

k get secret argocd-secret -o yaml | kubectl-neat > argocd-secret.yaml

cp argocd-secret.yaml argocd-secret-ca.yaml

base64 -w0 server/argocd-server.argocd.crt.pem | xclip -sel c

lvim argocd-secret-ca.yaml

base64 -w0 server/argocd-server.argocd.key.pem | xclip -sel c

lvim argocd-secret-ca.yaml

k apply -f argocd-secret-ca.yaml
```

## Ingress

```bash
k config set-context --current --namespace=argocd

lvim argocd-server-ingres.yaml

k apply -f [argocd-server-ingres.yaml](./argocd-server-ingres.yaml)

k get ingress

```

## Desabilitar o TLS para o Argo CD

Vamos usar o Ingress para o acesso https, para isso é necessário editar o arquivo
[argocd-cmd-params-cm.yaml](./argocd-cmd-params-cm.yaml) adicionando a chave `server.insegure = "true"`

```bash
k get configmaps -n argocd

k describe configmaps argocd-cmd-params-cm -n argocd

k get configmap argocd-cmd-params-cm -n argocd -o yaml | kubectl neat > argocd-cmd-params-cm.yaml

k apply -f argocd-cmd-params-cm.yaml
```

# Fazendo o Rollout

```bash
k get deployments.apps -n argocd

k rollout restart deployment argocd-server -n argocd

```

## Adicionar Entrada em /etc/hosts

```bash
sudo -H vim /etc/hosts

```

## Testar a URL

```bash
curl -I --cacert ca/ArgoCDRootCA.crt.pem https://argocd-server.argocd/
```

```
HTTP/2 200 
accept-ranges: bytes
content-security-policy: frame-ancestors 'self';
content-type: text/html; charset=utf-8
date: Sat, 22 Jul 2023 23:33:31 GMT
x-frame-options: sameorigin
x-xss-protection: 1
content-length: 788
```

```bash
https -h --verify ca/ArgoCDRootCA.crt.pem argocd-server.argocd
```

```
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 788
Content-Security-Policy: frame-ancestors 'self';
Content-Type: text/html; charset=utf-8
Date: Sat, 22 Jul 2023 23:37:57 GMT
X-Frame-Options: sameorigin
X-Xss-Protection: 1
```

## Documentação

[Set up Infrastructure for a High Availability K3s Kubernetes Cluster](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/infrastructure-setup/ha-k3s-kubernetes-cluster)

This tutorial is intended to help you provision the underlying infrastructure for a Rancher management server.

[Installing ArgoCD on k3s](https://blog.differentpla.net/blog/2022/02/02/argocd/)

Passo a passo para a instalação do Argo CD no K3s. Ele usa uma abordagem diferente que não necessita a
edição do arquivo `/etc/hosts` alterando o serviço de DNS do K3s.

São vários passos no artigo, primeiro a criação dos certificados [elixir-certs](https://blog.differentpla.net/blog/2021/12/21/elixir-certs/),
e finalmente a configuração do DNS no K3s (achei melhor não fazer isso) e finalmente resolvendo o erro ERR_TOO_MANY_REDIRECTS.

[Using CoreDNS for LoadBalancer addresses](https://blog.differentpla.net/blog/2021/12/29/coredns/)

> I’d like to be able to access my load-balanced services by name (docker.k3s.differentpla.net, for example) from outside my k3s cluster. I’m using --addn-hosts on dnsmasq on my router. This is fragile. Every time I want to add a load-balanced service, I need to edit the additional hosts file on my router, and I need to restart dnsmasq.
> 
> I’d prefer to forward the .k3s.differentpla.net subdomain to another DNS server, by using the --server option to dnsmasq. This means that I don’t need to touch my router once the forwarding rule is configured.
> 
> Kubernetes already provides CoreDNS for service discovery, so I’m going to use another instance of that.

[Error: `no matches for kind "Ingress" in version "extensions/v1beta1"`](https://stackoverflow.com/questions/69517855/microk8s-dashboard-using-nginx-ingress-via-http-not-working-error-no-matches)

[kubernetes - Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

Aqui encontrei as configurações de TLS e path.

[kubernetes - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

[nginx-ingress: Too many redirects when force-ssl is enabled](https://stackoverflow.com/questions/49856754/nginx-ingress-too-many-redirects-when-force-ssl-is-enabled)

Tive problemas de `Too many redirects...` ao configurar o TLS e cheguei até esse site onde uma das repostas seria usar o
argumento `--insecure` para o serviço argocd, mas essa não é a maneira ideal.

[How to Restart Kubernetes Pods With Kubectl](https://spacelift.io/blog/restart-kubernetes-pods-with-kubectl)

Não existe maneira de restartar um pod, a única maneira é com um `rollout restart`

kubectl rollout restart deployment <deployment_name> -n <namespace>

[kubectl-neat](https://github.com/itaysk/kubectl-neat)

Torna os arquivos exportados mais claros!

[Self Signed Certificate With Custom CA](https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309)

Passo a passo para criação da CA e certificado de servidor.

[Create a multiple domains (SAN) self-signed SSL certificate](https://transang.me/create-a-multiple-domains-self-signed-ssl-certificate-with-testing-scripts/)

Muito bem explicado, cria a CA, o sertificado e mostra como criar múltiplos nomes DNS no certificado.

[Installing ArgoCD on k3s](https://lumochift.org/blog/k3s-argocd)

Instalação básica com helm!

```bash
k3s kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd

k3s kubectl get pods -n argocd

k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

k3s kubectl port-forward svc/argocd-server -n argocd 1443:443

```

[SSL Certificate Verification](https://curl.se/docs/sslcerts.html)

