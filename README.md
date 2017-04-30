# nginx-fastcertificate

matsumoto-rさんの[ngx_mrubyで最初のHTTPSアクセス時に自動で証明書を設定可能にするFastCertificateの提案とPoC](http://hb.matsumoto-r.jp/entry/2017/03/23/173236)を参考に、[Let's Encrypt](https://letsencrypt.jp/)からSSL証明書を自動取得する仕組みを内包した nginx-fastcertificate を実現するDockerコンテナとdocker-compose設定例です。

## 全体像

![image](https://cloud.githubusercontent.com/assets/807671/25564520/fef96de8-2def-11e7-8379-0555cc5bcfb7.png)


## 使い方

以下のような yaml ファイルを用意します。

```yaml:docker-compose.yml
version: '3'
services:
  nginx:
    image: quay.io/akiray03/nginx-fastcertificate
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./logs:/usr/local/nginx/logs
    links:
      - redis:redis
    environment:
      NGINX_WORKER_PROCESSES: 2
      REDIS_HOST: "redis"
      RESOLVER_ADDRESS: 8.8.8.8

      # ホストのプライベートIPアドレスを指定する or CLOUD_PROVIDER を指定する
      CLOUD_PROVIDER: Amazon # or Google
      # INTERNAL_IP: 192.168.0.10

      # このサーバで終端するドメイン名を半角スペース区切りで指定
      SSL_DOMAINS: "test.example.com test2.example.com"

      # ドメインごとに接続先情報を記述します (test.example.com の接続先)
      test_example_com_PROXY_TO_HOST: INTERNAL_IP
      test_example_com_PROXY_TO_PORT: '3000'
      # test2.example.com のリバースプロキシ接続先
      test2_example_com_PROXY_TO_URL: "https://test2.original.example.com/"
    depends_on:
      - redis

  redis:
    image: redis:3.2-alpine
    expose:
      - '6379'
```

そして、以下のコマンドを実行することで、SSL証明書の自動取得が行われるnginxが起動します。

```bash
$ docker-compose up
```

### 環境変数の説明

| 項目 | 説明 |
|:--|:--|
| `SSL_DOMAINS`| サーバで終端するドメイン名を半角スペース区切りで指定します |
| `test_example_com_PROXY_TO_HOST` | リバースプロキシ接続先のIPアドレスを指定します |
| `test_example_com_PROXY_TO_PORT` | リバースプロキシ接続先のポートを指定します |
| `test_exmaple_com_PROXY_TO_URL`  | リバースプロキシ接続先のURLを指定します |
| `CLOUD_PROVIDER` | クラウドベンダー名を指定します。 `Amazon` または `Google` をサポートします |
| `INTERNAL_IP` | Dockerコンテナが動作するホストのプライベートIPアドレスを指定する |

## 解説

### `INTERNAL_IP` と `CLOUD_PROVIDER` について

 - リバースプロキシ先が nginx-certificate コンテナが動作する docker-compose にリンクされている場合は、 `INTERNAL_IP=127.0.0.1` と指定することでリバースプロキシが実現できます
 - リバースプロキシ先が docker-compose 外で動作している場合、ホストのプライベートIPを指定する必要があります
 - AmazonまたはGoogleのクラウドを利用している場合 `CLOUD_PROVIDER=Amazon` のように指定することで、メタデータAPI経由でIPアドレスを解決することができます

### リバースプロキシ先をURLで指定したい場合 (固定IPアドレスではなく、ドメインの場合)

 - リバースプロキシ先が固定IPの場合には、 `<domain_name>_PROXY_TO_URL` 設定値を利用します
 - [nginxのupstreamコンテキストを利用する方法](http://qiita.com/minamijoyo/items/183e51a28a3a9d79182f)によって、有償オプションを利用することなく、動的な名前解決を実現しています。

### 証明書の取得と有効期間

 - 冒頭にも書きましたが、SSL証明書は[Let's Encrypt](https://letsencrypt.jp/)から自動取得を行います
 - 最初のアクセス時にSSL証明書の発行とRedisへの永続化を行っていますので、数秒〜十数秒の時間がかかります。一方で2回目以降のアクセス時にはRedisから証明書を取得するので応答までの時間は(通常のWebサイトであれば)気にならないレベルになるでしょう

```
$ time curl https://b.test.yumiyama.com -o /dev/null

real    0m7.602s
user    0m0.020s
sys     0m0.000s
$ time curl https://b.test.yumiyama.com -o /dev/null

real    0m0.068s
user    0m0.012s
sys     0m0.004s
```

 - [Let's Encrypt](https://letsencrypt.jp/)の証明書の有効期限は90日間で、[60日ごとに更新することが推奨されて](https://letsencrypt.jp/blog/2015-11-09.html)います
 - nginx-fastcertificate でも推奨値に従って前回の証明書取得日から60日を経過した後の最初のリクエストで更新処理が行われます ([refs](https://github.com/akiray03/nginx-fastcertificate/blob/954d355f3838580316d28a85e169c78e47525be5/build/conf/nginx.conf#L75-L78))
