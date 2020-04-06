# ffmpeg wave unpacker plugin for Kirikiri

This plugin allows Kirikiri 2 and [Kirikiri Z](http://krkrz.github.io/) to decode audio files using the [ffmpeg](https://www.ffmpeg.org/) library.  

## How to use

1. Download `wuffmpeg.vx.y.z.7z` (where `x.y.z` is the version number) from the [Github release page](https://github.com/uyjulian/wuffmpeg/releases).  
2. Extract the archive using [7-Zip](https://www.7-zip.org/).
3. Add `@loadplugin module=wuffmpeg.dll` to your KAG scenario.
4. `@play storage=file.opus` will play `file.opus`.

For the full list of supported containers and codecs, see `supported_list.md`.  

## Building

After cloning submodules using `git submodule init` and `git submodule update`, a simple `make` will generate `wuffmpeg.dll`.  

## License

This project is licensed under the [GNU Lesser General Public License version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html) or (at your option) any later version.  
Please read the `LICENSE` file for more information.  

If you modify any part of this project and release the modified binaries of `wuffmpeg.dll`, you must also release the modified source code of `wuffmpeg.dll`.  
If you do not modify any part of this project and use the binaries provided on the [Github release page](https://github.com/uyjulian/wuffmpeg/releases), you do not need to release the modified source code since no modifications have been done.  
