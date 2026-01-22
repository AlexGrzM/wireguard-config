
WireGuard to bardzo prosty w konfiguracji VPN. 

WireGuard tworzy wirtualny adapter sieciowy o dowolnej nazwie, najczęściej `wg0`, `wg1` itd.  
Konfiguracja adaptera znajduje się w pliku:

`/etc/wireguard/<nazwa_adaptera>.conf`

## Instalacja i konfiguracja WireGuard


### Konfiguracja po stronie serwera

#### 1. Instalacja pakietu

```sh
sudo apt update 
sudo apt install wireguard
```

#### 2. Generowanie kluczy kryptograficznych

Najpierw generuje się klucz prywatny, który będzie używany do autentykacji:

```sh
wg genkey > private.key
```

Następnie na jego podstawie generuje się klucz publiczny, który pozwala innym hostom identyfikować serwer:

```sh
cat private.key | wg pubkey > public.key
```

#### 3. Utworzenie pliku konfiguracyjnego interfejsu

Najczęściej interfejs nazywa się `wg0`, ale nazwa może być dowolna.

```sh
sudo touch /etc/wireguard/wg0.conf
```

#### 4. Konfiguracja zapory sieciowej

WireGuard komunikuje się za pomocą szyfrowanych pakietów UDP na porcie określonym w pliku konfiguracyjnym.

```sh
sudo ufw allow <port>/udp
```

#### 5. Automatyczne uruchamianie przy starcie systemu

Aby WireGuard uruchamiał się automatycznie na interfejsie `wg0`:

```sh
sudo systemctl enable --now wg-quick@wg0.service
```


### Konfiguracja po stronie peer’a (klienta)

Proces konfiguracji po stronie peer’a wygląda bardzo podobnie.

```sh

sudo apt update sudo apt install wireguard  

#Generowanie klucza prywatnego 
wg genkey > private.key          

# Generowanie klucza publicznego  
cat private.key | wg pubkey > public.key

#Konfiguracja
sudo touch /etc/wireguard/wg0.conf  

sudo ufw allow <port>/udp  
sudo systemctl enable --now wg-quick@wg0.service
```


## Podstawowe komendy zarządzania WireGuard

### Włączanie i wyłączanie interfejsu

```sh
sudo wg-quick up <interfejs> # Włącza interfejs WireGuard na podstawie pliku konfiguracyjnego.
```


```sh
sudo wg-quick down <interfejs> # Wyłącza interfejs
```

### Dodawanie nowych peerów

Mimo że peerów można dodawać bezpośrednio w pliku konfiguracyjnym, plik ten bywa nadpisywany.  Zaleca się więc dodawanie peerów w ten sposób:

```sh
sudo wg set <interfejs> peer <klucz_publiczny_peera> allowed-ips <adresy_IP_peera>
```

### Usuwanie peerów

```sh
sudo wg set <interfejs> peer <klucz_publiczny_peera> remove
```

## Szczegóły konfiguracji

Jedyny wymagany plik konfiguracyjny należy utworzyć ręcznie w `/etc/wireguard/<nazwa_adaptera>.conf`

Plik składa się z:

**sekcji `[Interface]`** - opisującej host, na którym znajduje się konfiguracja
**Jednej lub wielu sekcji `[Peer]`** - opisujących inne hosty (serwer, klienci, zasoby)

### Przykładowa konfiguracja IPv4

```sh
/etc/wireguard/wg0.conf  

[Interface] 
PrivateKey = klucz_prywatny_tego_hosta 
Address = prywatny_adres_ip/CIDR
ListenPort = port_wireguard
   
[Peer]
PublicKey = klucz_publiczny_innego_hosta 
AllowedIPs = prywatne_adresy_IP 
Endpoint = publiczny_adres_ip:port
   
[Peer] 
PublicKey = klucz_publiczny_innego_hosta 
AllowedIPs = prywatne_adresy_IP 
Endpoint = publiczny_adres_ip:port

```

## Opis sekcji konfiguracyjnych


### [Interface]

**PrivateKey**  - Klucz prywatny hosta wygenerowany poleceniem `wg genkey`, zapisany w formacie base64.
    
**Address**  - Prywatny adres IP interfejsu WireGuard zapisany w notacji CIDR, np. `10.0.0.1/24`. Kolizja adresów IP lub niezgodność z `AllowedIPs` może skutkować odrzuceniem połączenia.

**ListenPort**  - Port UDP, na którym WireGuard będzie nasłuchiwał połączeń.

### [Peer]

Sekcji `[Peer]` może być wiele. Każda z nich opisuje jednego hosta, z którym zestawiane jest połączenie.

**PublicKey**  - Klucz publiczny hosta, wygenerowany poleceniem: `cat private.key | wg pubkey`
   
**AllowedIPs**  - Zakres adresów IP, które będą kierowane do tego peer’a przez interfejs WireGuard.  
Można podać wiele podsieci, oddzielonych przecinkami.

**Endpoint** - Adres IP i port, pod którym dostępny jest peer. Parametr ten jest automatycznie aktualizowany na podstawie ostatniego połączenia.

## Bastion Host

![alt-text](https://github.com/AlexGrzM/wireguard-config/blob/main/diagram.png)

Dowolna liczba sieci i hostów może zostać połączona z zasobami i serwerami za pomocą jednego **Bastion Hosta**.  

Każdy host i zasób łączy się wyłącznie z bastionem.

> **UWAGA**  
> Aby klienci nie musieli definiować wszystkich zasobów jako osobnych peerów, na Bastion Hoście należy włączyć przekazywanie IPv4:
> 
> `net.ipv4.ip_forward=1`
> 
> Następnie zastosować zmiany:
> 
> `sudo sysctl -p`

### Konfiguracja klientów / pracowników / zasobów Hetzner

```sh
#/etc/wireguard/wg0.conf
[Interface]
PrivateKey = <Indywidualny_Klucz_Prywatny> 
Address = 10.0.0.X 
ListenPort = 1234  

[Peer] 
PublicKey = <Klucz_Publiczny_Bastion_Hosta> 
AllowedIPs = 10.0.0.1/24 
Endpoint = 89.167.7.228:1234
```

### Konfiguracja Bastion Hosta

```sh
#/etc/wireguard/wg0.conf
[Interface] 
PrivateKey = <Klucz_Prywatny_Bastion_Hosta> 
Address = 10.0.0.1 
ListenPort = 1234  

[Peer] 
# A. Kowalski 
PublicKey = <Klucz_Publiczny_Hosta> 
AllowedIPs = 10.0.0.6/24  

[Peer]
# S. Piotrowska 
PublicKey = <Klucz_Publiczny_Hosta> 
AllowedIPs = 10.0.0.7/24  

[Peer] 
# Serwer MongoDB 
PublicKey = <Klucz_Publiczny_Serwera> 
AllowedIPs = 10.0.0.2/24
```

