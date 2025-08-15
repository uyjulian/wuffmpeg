吉里吉里のffmpegウェーブアンパッカープラグイン
==============================================

このプラグインにより、吉里吉里2および\ `吉里吉里Z <http://krkrz.github.io/>`__\ は、\ `ffmpeg <https://www.ffmpeg.org/>`__\ ライブラリを使用してオーディオファイルをデコードできます。

使い方
------

1. `Githubリリースページ <https://github.com/uyjulian/wuffmpeg/releases>`__\ から\ ``wuffmpeg.vx.y.z.7z``\ （\ ``x.y.z``\ はバージョン番号）をダウンロードします。
2. `7-Zip <https://www.7-zip.org/>`__\ を使用してアーカイブを抽出します。
3. KAGシナリオに\ ``@loadplugin module=wuffmpeg.dll``\ を追加します。
4. ``@play storage=file.opus``\ は\ ``file.opus``\ を再生します。

サポートされているコンテナとコーデックの完全なリストについては、\ ``supported_list.md``\ を参照してください。

建物
----

``git submodule init``\ および\ ``git submodule update``\ を使用してサブモジュールを複製した後、単純な\ ``make``\ が\ ``wuffmpeg.dll``\ を生成します。

ライセンス
----------

| このプロジェクトは、\ `GNU Lesser General Public
  Licenseバージョン2.1 <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>`__\ または（オプションで）以降のバージョンでライセンスされています。
| 詳細については、\ ``LICENSE``\ ファイルをお読みください。

| このプロジェクトの一部を変更し、変更された\ ``wuffmpeg.dll``\ のバイナリをリリースする場合は、変更された\ ``wuffmpeg.dll``\ のソースコードもリリースする必要があります。
| このプロジェクトのどの部分も変更せず、\ `Githubリリースページ <https://github.com/uyjulian/wuffmpeg/releases>`__\ で提供されるバイナリを使用する場合、変更が行われていないため、変更されたソースコードをリリースする必要はありません。
