# DerpiGET
A feature-rich [Derpibooru](http://derpibooru.org) post downloader written using BASH. Tool of Mass Equine Acquisition.

REMEMBER, not all artists want their work reposted. Please DerpiGET Responsibly & Respectfully.

## How do I use this?
Well, first a good thing to keep in mind is that this was written in BASH on Linux. You might find yourself having a very difficult time using this if you're trying it on a different platform!

To begin, download or clone the repository, all you really need is the `derpiget.sh` file itself. From there, pop open a terminal, make sure it's marked as executable, hand give it a shot! `./derpiget.sh --help`

For lots of juicy details, continue reading the README!

## Features & Functionality
DerpiGET was originally built for a very specific purpose, but has *long* since moved away from that... however it's original functionality remains a feature!

#### Arguments
DerpiGET has a plethora of them... so her are some explainations

| Argument | Functionality |
| :---: | --- |
| *none* | The default functionality. Downloads posts linked in dl_list.txt consecutively and names them with artist names and a few tags. Example `img/artist - cake, hugging, Rainbow Dash (POST ID).png` |
| --shimmie | Original purpose. Downloads posts linked in dl_list.txt consecutively, and generates CSV file for [Shimmie2](https://github.com/shish/shimmie2)'s bulk_add_csv extention. |
| --csvfix | Occasionally the `list.csv` generated by `--shimie` is malformed. This will go back through `dl_list.txt` and recreated it, without redownloading any images. |
| --linksnoop | Uses `xclip` to monitor your clipboard and saves every (unique) post link you copy to `dl_list.txt`. |
| --auto | Run in a silent, non-interactive mode (Option suggested by Pouar). |
| --search | Gets and stores the *entirity* of a set of search results to `dl_list.txt`. This option uses [Derpibooru's](https://derpibooru.org) own search engine to get the results, so *do* read up on their [Search Syntax](https://derpibooru.org/search/syntax)! If you're having trouble getting the results you want be aware that your *filter* (Default by default) affects the search results. You can't change this directly within DerpiGET, but you can change your filter, and even use private custom ones by using your cookies (See `cookies.txt`). Example of proper usage: `./derpiget.sh --search="dashie, hugging, cake"`. |
| --changelog | Outputs a list of changes between versions. |
| --genbashcomplete | Outputs a shell script file containing the `bash-completion` script for DerpiGET. (useful if you like tab-completeing arguments!) |
| --config | Use a *different* config file (maybe you have one for special occasions?). Example:`--config="alt.conf"` |
| --mkconf | Generate Default Config file `derpiget.conf`. |
| --clear | Pulls up a fancy menu that preform a variety of clean up actions (wipe any/multiple/all of the following `cookies.txt`, `dl_list.txt`, `list.csv`, Image Folder Contents). |
| --about | Gives you info about various topcis. Example: `./derpiget.sh --about="derpibooru"`.)
| --version | Outputs version info. |
| --help | Display the help message. |
| -? | Display the help message. |

#### Dependancies
DerpiGET *requires* some dependancies to run at all. Some specific features *optional* dependancies to function, but will not prevent you from using the other features without them. Here's a list of those things and what they're used for!

| Optional? | Dependency Name | Used For |
| :---: | :---: | :---: |
| No | wc (coreutils) | Various. |
| No | cut (coreutils) | Various. |
| No | wget | Downloading if images, tag inforamation, etc. |
| No | bc | Addition/Subtraction (Loop Handling). |
| No | grep | Various. |
| Yes | beep | If installed, `--linksnoop` will ask if DerpiGET should emit a beep everytime it records a new post link. |
| Yes | xclip | Required for `--linksnoop`. if the argument is used without this, it will output a message and exit. |

#### Files & Directories
DerpiGET itself is just one script, but it utilizes & creates a variety of files... here's some info on each of them.

| Derpiget.conf |
| --- |
| DerpiGET's config file! DerpiGET seeks this file in a variety of locations and uses the *first* one it finds. Locations it looks (in order) are as follows: Working Directory (`./derpiget.conf`), Home Directory (`~/.derpiget.conf`), System Directory (`/etc/derpiget.conf`)... you can also use an alternative config file with `--config="alternative.conf"`. The config file can have the following: dlpath=/file/path/here (Where to download files to?), serverimgpath=/webserver/file/path/here (Where files are located on a weberver (Used in `list.csv`), cookies=/path/to/cookies.txt (Text file containing Derpibooru cookies), dlcap=42 (Try to avoid downloading *more* than this number of files in a run) |

| derpibooru_strainer.csv |
| --- |
| Contains a list of tags to replace with another. For example, your [Shimmie2 Image Board](https://github.com/shish/shimmie2) may have a *species* tag category... you can add `" pegasus "," species:pegasus "` onto a line to change the pegasus tag. This works with multiword tags as well, but uses [Shimmie2's](https://github.com/shish/shimmie2) tag format instead of [Derpibooru's](http://derpibooru.org), so you would use `" Twilight_Sparkle ","Purple_Smart"` and ***NOT*** `" Twilight Sparkle","Purple Smart"`. Please Note that the space before and after your tags names are ***REQUIRED***, but skipping a space can allow you to replace portions of tags instead, for example `"is_a_duck ","is_a_bad_pony "` to modify the `OP is a duck` tag from Derpibooru |

| list.csv |
| --- |
| This file is generated by the `--shimmie` option, and contains information for [Shimmie2's](https://github.com/shish/shimmie2) bulk_upload_csv extention. If DerpiGET isn't hosted on yourserver, you want to ensure that you upload this file to the server, along with the images files which need to be in the correct directory on the server (`example.com/bulkaddcsv` by default, change-able in `derpiget.conf`) |

| cookies.txt |
| --- |
| This file is a text file that *you* would have to create that would contain cookies from [Derpibooru](http://derpibooru.org), in order to allow you to use different filters from the default with the `--search` option. If using a login cookie, you can use a logged in web browser to change your filter, DerpiGET will follow whichever you have set. ***SECURITY/SAFETY NOTICE: NEVER EVER STORE YOUR COOKIES.TXT IN AN INSECURE LOCATION, FAILING TO KEEP THIS FILE SAFE COULD LEAD TO YOUR [DERPIBOORU](http://derpibooru.org) ACCOUNT BEING COMPROMIZED!*** |

| dl_list.txt |
| --- |
| The download list. You can modify this file *directly* with ease. Simply copy/paste [Derpibooru](http://derpibooru.org) post URLS (such as http://derpibooru.org/1) and paste them one per line. Alternatively the `--linksnoop` option can monitor your clipboard for copied post links, eliminating the need to paste them, or alt-tab out of your browser at all. Using --search can generate this file from the results of a Search Query. |

#### Environment Variables
Environment Variables that effect DerpiGET's behavior.

| Variable Name | Value | Effect |
| --- | --- | --- |
| $SILVERMOON_DEBUG | *NON_EMPTY* | DerpiGET will display debug messages |

## Questions & Answers
Got questions? This section might answer some.

| Q: Why Would you Makes This? |
| --- |
| A: I really like MLP, and [Derpibooru](http://derpibooru.org) is an amazing image board... You can never have too much pony. |

| Q: Does this use [Derpibooru's API](https://derpibooru.org/pages/api)? |
| --- |
| A: No, not at all. This actually downloads the HTML, stores it in a variable, digs information (tags and source) out of it, and then download's the image using the Full Size URL. Because of this, if [Derpibooru's](https://derpibooru.org) website changes it's HTML, DerpiGET has in the past and will likely break again as a result. |

| Q: Will this work on Windows? |
| --- |
| A: Not Without a *lot* of extra stuff and work; not under normal circumstances. It may function without modification within Windows 10's [Windows Subsystem For Linux or WSL](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide). |

| Q: Does this work in [Termux](https://github.com/termux/termux-app)? |
| --- |
| A: I don't think so, but it would likely be trivial to get it to do so. |

| Q: Will you port this to (Insert OS Name Here) |
| --- |
| A: Probably not. |