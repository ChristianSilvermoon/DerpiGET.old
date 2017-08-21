#!/bin/bash
#Mass download Derpibooru link list for Shimmie2's Bulk Add CSV Extention
#
#By Christian "Krissy" Silvermoon
scriptversion="v17.7.11-git by Christian \"Krissy\" Silvermoon"

function help_message {

	echo "USAGE: derpiget [ARGUMENTS]

	ARGUMENTS
	  --shimmie		Download posts, create shimmie2 bulkadd CSV
	  --csvfix		Repair a shimmie2 CSV (if dl_list.txt is unchanged)
	  --linksnoop		Generate dl_list.txt by stalking your clipboard
	  --auto		Run in non-interactive mode
	  --search		Generate dl_list.txt containing ALL search results
	  --changelog		Display a Changelog
	  --genbashcomplete	Output a BASH Completion script to file
	  --config		Use Alternate Config File
	  --mkconf		Generate default config @ './derpiget.conf'
	  --clear		Clear data/files from previous runs
	  --about		Display information about features
	  --version		Display version information
	  --help		Display this message
	  -?			Display this message
	" | sed 's/^	//g'
	if [ "$(command -v ponysay)" != "" ]; then
		echo -e "  You have super \e[1mPony Power\e[0m!"
	fi
}

function derpitag_port {
	#Usage derpitag_port "tags"
	taglist="$1"

	#Replace HTML Codes with their actual characters
	taglist=$(echo "$taglist" | sed "s/&#39;/\'/g")
	
	if [ -a "derpibooru_strainer.csv" ]; then
		echo -n ""
	else
		touch "derpibooru_strainer.csv"
		echo "# Lines starting with \"#\" are commented" >> "derpibooru_strainer.csv"
		echo "#" >> "derpibooru_strainer.csv"
		echo "# Syntax Example" >> "derpibooru_strainer.csv"
		echo "# \" fluttershy \",\" character:Fluttershy \"" >> "derpibooru_strainer.csv"
		echo "# \" earth_pony \",\" species:earth_pony \"" >> "derpibooru_strainer.csv"
		echo "#" >> "derpibooru_strainer.csv"
		echo "# For more info see" >> "derpibooru_strainer.csv"
		echo "# derpiget --about \"derpibooru_strainer.csv\"" >> "derpibooru_strainer.csv"
	fi


	#Handle Initial Reformating from Derpibooru Format
	taglist=$(echo "$taglist" | sed 's/, /!/g' | sed 's/ /_/g' | sed 's/!/ /g')
	taglist=$(echo " $taglist")

	#Alter tags based on derpibooru_strainer.csv
	strainercount=$(cat derpibooru_strainer.csv | grep -v "^#" | wc -l)
	strainercount=$(echo "$strainercount + 1" | bc)
	strainercurrent="1"
	while [ "$strainercurrent" != "$strainercount" ]; do
		tmp_original=$(cat "derpibooru_strainer.csv" | grep -v "^#" | sed 's/\"//g' | head -$strainercurrent | tail -1 | cut -d',' -f 1)
		tmp_replace=$(cat "derpibooru_strainer.csv" | grep -v "^#" | sed 's/\"//g' | head -$strainercurrent | tail -1 | cut -d',' -f 2)
		taglist=$(echo "$taglist" | sed "s/$tmp_original/$tmp_replace/g")
		strainercurrent=$(echo "$strainercurrent + 1" | bc)
	done

	#Tag GIF if mimetype is GIF
	if [ "$mimetype" = "gif" ]; then
		echo -n "GIF "
	fi
	echo "$taglist DerpiGet"
}

function tag_filter {
	#Filter tags using tag_filter.csv
	#Function not implemented
	echo -n ""
}

function check_dlist {

	if [ -a "dl_list.txt" ]; then
		if [ "$robomode" != "true" ]; then
			echo -n "Found Download List... "
		fi
	else
		echo "Error, No List"
		echo "Please paste 1 Derpibooru post link per line in the file: "
		echo "dl_list.txt"
		echo
		exit 1
	fi

}

function derpiget_normal {
	#Donwload images from dl_list only
	check_dlist
	if [ "$robomode" != "true" ]; then
		echo "Any files located in $dlpath/ will be deleted (rm -rf)"
		echo ""
		echo -n "Continue? [Y/N] "
		read option
	else
		option="y"
	fi

	if [ "$option" = "y" -o "$option" = "Y" ]; then
		#Clear img/
		rm -rf "$dlpath"/* > /dev/null 2>&1
		
		#Read dl_list.txt for count
		dloadlinkcount=$(cat dl_list.txt | wc -l)
		dloadlinkcount=$(echo "$dloadlinkcount + 1" | bc)
		current="1"
		if [ "$robomode" != "true" ]; then
			if [ "$dloadlinkcount" -gt "$dlcap" ]&&[ "$dlcap" != "0" ]; then
				echo -e "\nThe number of links in the download list exceeds your"
				echo "set download cap of $dlcap by $(echo "$dloadlinkcount - $dlcap" | bc) posts!"
				echo "What to do?"
				echo "1 - Download only the first $dlcap images"
				echo "2 - Continue and ignore the Download cap"
				echo ""
				echo "Press any other key to Abort"
				read -rsn1 option
				if [ "$option" = "1" ]; then
					dl_policy="partial"
				elif [ "$option" = "2" ]; then
					dl_policy="full"
				else
					echo "Aborted."
					exit
				fi
			fi
			echo "$( echo "$dloadlinkcount -1" | bc) Link(s) to fetch"
		else
			dl_policy="full"
		fi

		#Adjust $dlcap to account for offset
		dlcap=$(echo "$dlcap + 1 " | bc)

		while [ "$current" != "$dloadlinkcount" ]; do
			#Display Counter
			
			
			#read dl_list.txt for current URL
			url=$(cat dl_list.txt | head -$current | tail -1)

			#Download web page to variable, insert line breaks at tag closing '>' symbol
			html="$(wget -q -O- "$(cat dl_list.txt | head -$current | tail -1)" | sed 's/>/>\n/g')"
			if [ "$robomode" != "true" ]; then
				echo -n "$current/$(echo "$dloadlinkcount - 1" | bc): "
				echo -n "Got HTML... "
			fi 

			#Save image as artist_1 artist_2 artist_3 - tag_1 tag_2 tag_3 (PostID)

			#Get Tags
			tags=$(echo "$html" | grep "tag dropdown" | sed 's/\" /\"\n/g' | grep "data-tag-name=" | cut -d"=" -f 2 | sed 's/\"//g' | tr '\n' ',' | sed 's/,/, /g')
			#echo "TAGS ripped from HTML:  $tags"
			tags=$(echo "$tags" | sed 's/, /,/g' | sed 's/ /_/g' | sed 's/:/_/g' | sed 's/,/ /g')

			#Prepare file name
			endname=$(
			if [ "$(echo "$tags" | tr ' ' '\n' | grep "artist_" | sed 's/artist_//g' | head -3 | tr '\n' ' ')" = "" ]; then
				echo -n "Unknown_Artist "
			else
				echo "$tags" | tr ' ' '\n' | grep "artist_" | sed 's/artist_//g' | head -3 | tr '\n' ' '
			fi
			echo -n "- "
			echo "$tags" | tr ' ' '\n' | grep -v "artist_" | grep -v "comic_" | head -3 | tr '\n' ' '
			echo -n "("

			#Get Post ID
			echo -n "$html" | head -10 | tr ' ' '\n' | grep "#" | tr -d '#' | tr -d '\n'
			echo -n ")"
			)
			if [ "$robomode" != "true" ]; then
				echo -n "Got Tags... "
			fi


			#Get Image File
			wget -q -O "$dlpath/$current" $(echo "$html" | grep "View this image at full res with a short filename" | sed 's/\" /\"\n/g' | sed 's/href=\"/http:/g' | sed 's/\">//g' | grep "http:" | sed 's/http:/https:/g')
			
			if [ "$robomode" != "true" ]; then
				echo "Got Image... "
			fi
			
			#Set correct file extention
			mimetype=$(derpiget_idfiletype "$dlpath/$current")
			imgname=$(echo -n "$endname"; echo ".$mimetype")
			mv "$dlpath/$current" "$dlpath/$imgname"

			#add to counter
			current=$(echo "$current + 1" | bc)

			#Alter counter based on $dl_policy
			if [ "$dl_policy" = "partial" ]; then
				if [ "$current" = "$dlcap" ]; then
					echo "Downlaod Cap Reached, Stopped."
					current="$dloadlinkcount"
				fi
			fi

		done
		if [ "$robomode" != "true" ]; then
			echo -e "Fetched From Derpibooru\n-----------------------\n$(ls $dlpath/ -1)" | less
		fi
	else
		echo "Aborted"
	fi

}

function derpiget_shimmie {
	check_dlist

	#Remove Existing Files
	if [ "$1" = "--csvfix" ]; then
		if [ -a "list.csv" ]; then
			if [ "$robomode" != "true" ]; then
				echo -n "Overwrite list.csv? [Y/N] "
				read option
			else
				option="y"
			fi

			if [ "$option" = "y" -o "$option" = "Y" ]; then
				echo -n ""
			else
				echo "Aborted"
				exit
			fi
		fi
		echo -n ""
	else
		if [ "$robomode" != "true" ]; then
			echo "Any files located in $dlpath/ will be deleted"
			echo "If list.csv exists, it will be overwritten"
			echo ""
			echo -n "Continue? [Y/N] "
			read option
		else
			option="y"
		fi

		if [ "$option" = "y" -o "$option" = "Y" ]; then
			#Clear img/
			rm -rf "$dlpath"/* > /dev/null 2>&1
		else
			echo "Aborted"
			exit
		fi
	fi

	echo -n "" > ./list.csv

	dloadlinkcount=$(cat dl_list.txt | wc -l)
	dloadlinkcount=$(echo "$dloadlinkcount + 1" | bc)
	current="1"
	if [ "$robomode" != "true" ]; then
		if [ "$dloadlinkcount" -gt "$dlcap" ]&&[ "$dlcap" != "0" ]; then
			echo -e "\nThe number of links in the download list exceeds your"
			echo "set download cap of $dlcap by $(echo "$dloadlinkcount - $dlcap" | bc) posts!"
			echo "What to do?"
			echo "1 - Download only the first $dlcap images"
			echo "2 - Continue and ignore the Download cap"
			echo ""
			echo "Press any other key to Abort"
			read -rsn1 option
			if [ "$option" = "1" ]; then
				dl_policy="partial"
			elif [ "$option" = "2" ]; then
				dl_policy="full"
			else
				echo "Aborted."
				exit
			fi
		fi
		echo "$( echo "$dloadlinkcount -1" | bc) Link(s) to fetch"
	else
		dl_policy="full"
	fi

	#Adjust $dlcap for offset
	dlcap=$(echo "$dlcap + 1" | bc)
	while [ "$current" != "$dloadlinkcount" ]; do
		url=$(cat dl_list.txt | head -$current | tail -1)
		#Download web page to variable, insert line breaks at tag closing '>' symbol
		html="$(wget -q -O- "$(cat dl_list.txt | head -$current | tail -1)" | sed 's/>/>\n/g')"
		
		if [ "$robomode" != "true" ]; then
			echo -n "$current/$(echo "$dloadlinkcount - 1" | bc): "
			echo -n "Got HTML... "
		fi

		#Get Image File
		if [ "$1" = "--csvfix" ]; then
			echo -n ""
		else
			wget -q -O "$dlpath/$current" $(echo "$html" | grep "View this image at full res with a short filename" | sed 's/\" /\"\n/g' | sed 's/href=\"/http:/g' | sed 's/\">//g' | grep "http:" | sed 's/http:/https:/g')
			if [ "$robomode" != "true" ]; then
				echo -n "Got Image... "
				#echo "bulkaddcsv/$current"
				#echo ""
			fi
		fi

		#CSV Fix, is image missing?
		if [ "$1" = "--csvfix" ]; then
			if [ -a "$dlpath/$current.*" ]; then
				echo -n ""
			else
				wget -q -O "$dlpath/$current" $(echo "$html" | grep "View this image at full res with a short filename" | sed 's/\" /\"\n/g' | sed 's/href=\"/http:/g' | sed 's/\">//g' | grep "http:" | sed 's/http:/https:/g')
				if [ "$robomode" != "true" ]; then
					echo -n "Got Missing Image... "
					#echo "bulkaddcsv/$current"
					#echo ""
				fi
				mimetype=$(derpiget_idfiletype "$dlpath/$current")
				imgname=$(echo -n "$current"; echo ".$mimetype")
				mv "$dlpath/$current" "$dlpath/$imgname"
			fi
		fi

		#Set correct file extention
		if [ "$1" = "--csvfix" ]; then
			#If not donwloading images, get mimetype from existing file
			mimetype=$(derpiget_idfiletype "$dlpath/$current")
		else
			mimetype=$(derpiget_idfiletype "$dlpath/$current")
			dbgmsg "Mimetype: $mimetype"
		fi
		imgname=$(echo -n "$current"; echo ".$mimetype")
		dbgmsg "Image Name: $imgname"

		if [ "$1" != "--csvfix" ]; then
			mv "$dlpath/$current" "$dlpath/$imgname"
		fi

		#Get Tags
		tags=$(echo "$html" | grep "tag dropdown" | sed 's/\" /\"\n/g' | grep "data-tag-name=" | cut -d"=" -f 2 | sed 's/\"//g' | tr '\n' ',' | sed 's/,/, /g')
		#echo "TAGS ripped from HTML:  $tags"
		tags=$(derpitag_port "$tags")
		if [ "$robomode" != "true" ]; then
			echo -n "Got Tags... "
			#echo "$tags"
			#echo ""
		fi

		#Get Source
		source=$(echo "$html" | grep "dc:source" | sed 's/\" /\"\n/g' | grep "href=" | sed 's/href=\"//g' | sed 's/\">//g')
		if [ "$robomode" != "true" ]; then
			echo -n "Got Source... "
			#echo "$source"
			#echo ""
		fi

		if [ "$source" = "" ]; then
			source="$url"
		fi

		#Update CSV
		#CSV format: "/path/to/image.jpg","spaced tags","source","rating s/q/e","/path/thumbnail.jpg"
		if [ "$robomode" != "true" ]; then
			echo "CSV Updated!"
		fi

		echo "\"$serverimgpath/$imgname\",\"$tags\",\"$source\",\"\",\"\"" >> list.csv

		#add to counter
		current=$(echo "$current + 1" | bc)
		#Alter counter based on $dl_policy
		if [ "$dl_policy" = "partial" ]; then
			if [ "$current" = "$dlcap" ]; then
				echo "Downlaod Cap Reached, Stopped."
				current="$dloadlinkcount"
			fi
		fi
	done
	if [ "$robomode" != "true" ]; then
		echo ""
	fi
}

function derpiget_linksnoop {
	if [ -a "dl_list.txt" ]; then
		echo -n "Overwrite dl_list.txt? [Y/N] "

		read option
		if [ "$option" = "y" -o "$option" = "Y" ]; then
			echo -n "" > dl_list.txt
		else
			echo ""
			echo -n "Append instead? [Y/N] "
			read option
			if [ "$option" = "Y" -o "$option" = "y" ]; then
				echo ""
			else
				echo "Aborted"
				exit
			fi
		fi
	fi

	if [ "$(command -v beep)" != "" ]; then
		echo "It looks like you have 'beep' installed."
		echo -n "Beep the PC Speaker on link record? [Y/N] "
		read -rsn1 option
		if [ "$option" = "y" -o "$option" = "Y" ]; then
			echo "Beep Enabled"
			savebeep="true"
		else
			echo "Beep NOT enabled"
		fi
	else
		echo "If 'beep' were available, DerpiGET could (optionally)"
		echo "beep your PC Speaker to notify you that a link has been saved"
	fi
	echo ""

	echo "Copy a Derpibooru Post Link to begin!"
	while true; do
		#Get Link From Clipboard
		currentlink=$(xclip -o selection | grep "derpibooru.org/[0-9]" | cut -d'?' -f 1)

		#If Current Link is the same, do nothing
		if [ "$currentlink" = "$oldlink" ]; then
			echo -n ""
		else
			clear

			#Display Link Counter
			echo "DerpiGET Link Snoop. (CTRL+C to stop at any time)"
			echo -n "Link Count: "
			echo "$(cat dl_list.txt | wc -l) + 1 " | bc


			#Display Clipboard Contents
			echo -n "Clipboard: "
			if [ "$(echo $currentlink | grep -E "^(http|https)://derpibooru.org/[0-9]")" = "" ]; then
				echo -e "\e[31m$(xclip -o selection)\e[0m"
				echo ""
			else
				echo -e "\e[32m$currentlink\e[0m"

				echo ""

				#Store link to dl_list.txt if it's a Derpibooru Post link
				#But only if it's not already in dl_list.txt
				if [ "$(cat dl_list.txt | grep "$currentlink")" = "" ]; then
					echo "$currentlink" >> dl_list.txt
					if [ "$savebeep" = "true" ]; then
						beep -f 400 -l 20
					fi
				fi

			fi

			echo "15 Most Recent (Bottom to Top)"
			cat -n dl_list.txt | tail -15 | cut -d"?" -f 1 | sed 's/^ *//g'

			oldlink="$currentlink"
		fi

		sleep .05s
	done
}

function derpiget_search {
	#Generate dl_list.txt based on ALL search results
	#URL Encode Search
	dbgmsg "--function: derpiget_search--"
	if [ "$robomode" != "true" ]; then
		if [ "$1" = "" ]; then
			echo "What are you searching for?"
			echo ""
			echo "Example of Proper Argument Usage"
			echo "deripget --search=\"dashie, hugging\""
			echo ""
			echo "Use Derpibooru Search Syntax!"
			exit
		else
			echo -n ""
		fi

		echo "Be very cautious before using the generated dl_list.txt"
		echo "It will contain a link to EVERY search result"

		echo "The purpose of this option is for mass downloading"
		echo "The results of a FINE TUNED search"
		echo
		echo "Please review yours search before unintentionally"
		echo "Downloading over 1000 posts or something!"
		echo ""

		dbgmsg "--Check existance of Cookies File--"
		if [ -a "$cookies" ]; then
			echo -n ""
		else
			echo "Image Results are limited to the default filter"
			echo "You can use cookies.txt to use other filters."

			echo "For more info use"
			echo "derpiget --about \"cookies.txt\""
			echo -n "" > "$cookies"
		fi
		echo "Search: $1"
	fi


	search=$(echo "$1" |
	sed 's/ /%20/g' |
	sed 's/!/%21/g' |
	sed 's/#/%23/g' |
	sed 's/\$/%24/g' |
	sed 's/&/%26/g' |
	tr "'" '!' |
	sed 's/!/%27/g' |
	sed 's/(/%28/g' |
	sed 's/)/%29/g' |
	sed 's/*/%2A/g' |
	sed 's/+/%2B/g' |
	sed 's/,/%2C/g' |
	sed 's/\//%2F/g' |
	sed 's/:/%3A/g' |
	sed 's/;/%3B/g' |
	sed 's/=/%3D/g' |
	sed 's/?/%3F/g' |
	sed 's/@/%40/g' |
	sed 's/\[/%5B/g' |
	sed 's/\]/%5D/g')
	
	page=1
	url="https://derpibooru.org/search?page=$page&utf8=%E2%9C%93&sbq=$search"
	if [ "$robomode" != "true" ]; then
		echo "Search URL: $url"
		dbgmsg "\$cookies=$cookies"
		echo -n "Results: "
		resultcount=$(wget --load-cookies="$cookies" -q -O- "$url" | sed 's/of <strong>/\nResults:/g' | sed 's/>/>\n/g' | sed 's/</\n</g' | grep "Results:" | cut -d':' -f "2")
		if [ "$resultcount" = "" ]; then
			echo -e "\e[31m0\e[0m"
			echo ""
			echo "I'm affraid these are not the ponies you are looking for."
			echo "AKA yor search returned no results... sorry..."
			echo ""
			echo "Did you form your search correctly?"
			echo "For help: https://derpibooru.org/search/syntax"
			exit
		fi
		echo "$resultcount"
		echo ""
		echo -n "Continue? [Y/N] "
		read option
		if [ "$option" = "y" -o "$option" = "Y" ]; then
			echo -n ""
		else
			echo "Aborted"
			exit
		fi

		if [ -a "dl_list.txt" ]; then
			echo -n "Overwrite dl_list.txt? [Y/N] "

			read option
			if [ "$option" = "y" -o "$option" = "Y" ]; then
				echo -n "" > dl_list.txt
			else
				echo ""
				echo -n "Append instead? [Y/N] "
				read option
				if [ "$option" = "Y" -o "$option" = "y" ]; then
					echo ""
				else
					echo "Aborted"
					exit
				fi
			fi
		fi
	fi

	nextpagetest=true

	until [ "$nextpagetest" = "false" ]; do
		#GET HTML
		html=$(wget --load-cookies="$cookies" -q -O- "$url" | sed 's/>/>\n/g')

		dbgmsg "Extracted Posts from Page: $page of search results"

		#Extract list of post links
		echo "$html" | grep "Tagged:" | sed 's/title/\ntitle/g' | grep "<a href" | cut -d'?' -f 1 | tr -d '=' | tr -d '<' | tr -d '"' | sed 's/a href/https:\/\/derpibooru.org/g' >> dl_list.txt

		#Test for next page
		if [ "$(echo "$html" | grep "Next Page")" = "" ]; then
			nextpagetest="false"
		else
			page=$(echo "$page + 1" | bc)
			url="https://derpibooru.org/search?page=$page&utf8=%E2%9C%93&sbq=$search"
		fi
	done
	cat dl_list.txt | wc -l
	exit

}

function derpiget_clear {
	#Clean up excess files, etc.
	loop=true
	clearimgdir="false"
	clearcsv="false"
	clearcookies="false"
	cleardlist="false"
	while [ "$loop" = "true" ]; do
		clear
		echo "Clear what?"
		echo -e "(Press Any Listed Key)\n"
		echo -e "\e[1m# - Item		Status\e[0m"
		echo -n "1 - Cookies		"
		if [ "$clearcookies" = "false" ]; then
			echo -en "\e[31m"
		else
			echo -en "\e[32m"
		fi
		echo -e "$clearcookies\e[0m"
		echo -n "2 - dl_list.txt		"
		if [ "$cleardlist" = "false" ]; then
			echo -en "\e[31m"
		else
			echo -en "\e[32m"
		fi
		echo -e "$cleardlist\e[0m"
		echo -n "3 - list.csv		"
		if [ "$clearcsv" = "false" ]; then
			echo -en "\e[31m"
		else
			echo -en "\e[32m"
		fi
		echo -e "$clearcsv\e[0m"
		echo -n "4 - Image Folder	"
		if [ "$clearimgdir" = "false" ]; then
			echo -en "\e[31m"
		else
			echo -en "\e[32m"
		fi
		echo -e "$clearimgdir\e[0m"
		echo ""
		echo "C - Continue & Clear"
		echo "Q - Quit Without Clearing"
		echo ""
		read -rsn1 option

		if [ "$option" = "1" ]; then
			if [ "$clearcookies" = "false" ]; then
				clearcookies="true"
			else
				clearcookies="false"
			fi
		elif [ "$option" = "2" ]; then
			if [ "$cleardlist" = "false" ]; then
				cleardlist="true"
			else
				cleardlist="false"
			fi
		elif [ "$option" = "3" ]; then
			if [ "$clearcsv" = "false" ]; then
				clearcsv="true"
			else
				clearcsv="false"
			fi
		elif [ "$option" = "4" ]; then
			if [ "$clearimgdir" = "false" ]; then
				clearimgdir="true"
			else
				clearimgdir="false"
			fi
		elif [ "$option" = "C" -o "$option" = "c" ]; then
			echo -n "Are you sure? [Y/N] "
			read -rsn1 option
			if [ "$option" = "y" -o "$option" = "Y" ]; then
				loop=false
				echo ""
			fi
		elif [ "$option" = "Q" -o "$option" = "q" ]; then
			echo -n "Abort? [Y/N] "
			read -rsn1 option
			if [ "$option" = "y" -o "$option" = "Y" ]; then
				echo -e "\n\nAborted"
				exit
			fi

		fi
	done

	if [ "$clearcookies" = "true" ]; then
		echo -n "" > "$cookies"
		echo "Cleared Cookies"
	fi

	if [ "$clearcsv" = "true" ]; then
		echo -n "" > list.csv
		echo "Cleared list.csv"
	fi

	if [ "$clearimgdir" = "true" ]; then
		rm -rf "$dlpath"/*
		echo "Cleared Image Directory"
	fi

	if [ "$cleardlist" = "true" ]; then
		echo -n "" > dl_list.txt
		echo "Cleared dl_list.txt"
	fi
	echo ""
	echo "Finished Clearing."
}

function derpiget_about {
	if [ "$1" = "" ]; then
		echo -e "You must specify a topic\n"
		echo "Example"
		echo "  derpiget --about=\"topic\""
		echo ""
		echo "Topics"
		echo "  derpiget			This script in general"
		echo "  derpibooru			The site the script was made for"
		echo "  cookies.txt			Cookies used by wget"
		echo "  dl_list.txt			List of posts to download"
		echo "  list.csv			Post Information for Shimmie2"
		echo "  derpibooru_strainer.csv	Tag filtering information"
		echo "  robomode			Details about non-intarctive mode"
		echo "  shimmie			Image Board"
		echo "  genbashcomplete		Output bash completion script to file"
		ecoh "  debugging		How to get more info?"
	elif [ "$1" = "derpiget" ]; then
		echo "DerpiGET"
		echo "  Script for mass downloading posts from"
		echo "  http://derpibooru.org"
		echo ""
		echo "  Written by Christian \"Krissy\" Silvermoon"
	elif [ "$1" = "derpibooru" ]; then
		echo "Derpibooru"
		echo "  A My Little Pony: Friendship is Magic fandom image board"
		echo ""
		echo "  See Below for more details"
		echo "  http://derpibooru.org/about"
	elif [ "$1" = "cookies.txt" ]; then
		echo "cookies.txt"
		echo "  Contains cookies used by wget"
		echo ""
		echo "  You can export your Derpibooru Cookies"
		echo "  from a web browser for use with"
		echo "  DerpiGET. In order to use a filter other"
		echo "  than \"Default\""
		echo ""
		echo "  Unless you're SPECIFICALLY trying to use"
		echo "  a filter that requires access to your account"
		echo "  avoid using ANY login cookies, as this may put"
		echo "  your user account at risk if your cookies.txt"
		echo "  should somehow fall into the wrong hooves!"
		echo ""

		echo "  Mozilla Firefox addon for exporting cookies"
		echo "  https://addons.mozilla.org/en-US/firefox/addon/export-cookies/?src=api"
		echo ""
		echo "  To remove cookies unrelated to Derpibooru, use this command"
		echo "  cat cookies.txt | grep \"derpibooru\" > newcookies.txt"

	elif [ "$1" = "dl_list.txt" ]; then
		echo "dl_list.txt"
		echo "  Download list for DerpiGET"
		echo ""
		echo "  When downloading images from"
		echo "  Derpibooru, DerpiGET will download"
		echo "  each post one after anoher starting"
		echo "  at the top of the list and working it's"
		echo "  way to the bottom"
		echo ""
		echo "  You should place one post link per line, like so:"
		echo "  https://derpibooru.org/1"
		echo "  https://derpibooru.org/2"
		echo "  https://derpibooru.org/3"
		echo ""
		echo "  Alternatively \"--search\" and \"--linksnoop\" can handle"
		echo "  The creation of a dl_list.txt file for you."

	elif [ "$1" = "list.csv" ]; then
		echo "list.csv"
		echo "  Comma Seperated Value file for Shimmie2"
		echo ""
		echo "  This is for use with a Shimmie2 Image Board's"
		echo "  bulkaddcsv extention for mass uploads along with"
		echo "  tagging information, etc. for all posts."
		echo ""
		echo "  When DerpiGET was first created, downloading images"
		echo "  and creation of this file from Derpibooru's tags"
		echo "  was it's only function."
		echo ""
		echo "  This script assumes that images are located in"
		echo "  http://example.com/bulkaddcsv/img"
		echo ""
		echo "  When stored and used on a server, DerpiGET was originally"
		echo "  intended to be ran from the \"/bulkaddcsv/\" directory"
		echo "  of a webserver."
	elif [ "$1" = "derpibooru_strainer.csv" ]; then
		echo "derpibooru_strainer.csv"
		echo "  Comma Seperated Value file for tag filtering"
		echo "  Yes, the name IS a joke about kitchen strainers"
		echo "  A more fitting solution would be to use Shimmie's"
		echo "  aliases, but if for whatever reason you don't want to"
		echo "  use this instead."
		echo ""
		echo "  This file is used when to alter tags durring saving"
		echo "  of images. when --shimmie or --csvfix is used."
		echo ""
		echo "  File Syntax"
		echo "  #Commented Line"
		echo "  \" to_be_replaced \",\" tag_to_replace_with \""
		echo ""
		echo "  Important"
		echo "  Do not add comments at the end of lines"
		echo "  Do not leave uncommented blank lines"
		echo "  Insert spaces at the beginning and end of"
		echo "  Your tags, always, unless specifically targeting"
		echo "  a portion of a tag like 'oc:character'"
		echo "  which you can use"
		echo ""
		echo "  \" oc:\",\" character:oc:\""
		echo ""
		echo "  to replace. If a character must be escaped for"
		echo "  sed to use it, then it MUST be escaped here."
		echo "  Remember to seperate tags with spaces, not commas,"
		echo "  as by this point, derpibooru's tags have been changed from"
		echo "  \"safe, artist:this dude, example\" to"
		echo "  \"safe artist:this_dude example\""
	elif [ "$1" = "shimmie" ]; then
		echo "Shimmie"
		echo "  A pretty neat GPLv2 booru-style Image Board"
		echo ""
		echo "  For more details, see"
		echo "  https://github.com/shish/shimmie2"
		echo "  https://code.shishnet.org/shimmie2/"
	elif [ "$1" = "robomode" ]; then
		echo "Robomode"
		echo "  Noninteractive use of DerpiGET"
		echo "  It is mostly silent and will NOT prompt"
		echo "  you before deleting or altering files!"
		echo ""
		echo "  This can done in one of the two following ways"
		echo ""
		echo "  derpiget --auto [Arguments]"
		echo "  OR"
		echo "  robomode=\"true\" derpiget [Arguments]"
		echo ""
		echo "  NOT all options work in Robomode"
		echo "  These, however do"
		echo ""
		echo "  derpiget --auto --search=\"example\""
		echo "  (Appends ONLY. Outputs number of links in dl_list.csv to stdout)"
		echo ""
		echo "  derpiget --auto"
		echo "  derpiget --auto --shimmie"
		echo "  derpiget --auto --csvfix"

	elif [ "$1" = "genbashcomplete" ]; then
		echo "genbashcomplete
		  creates derpiget_completion.sh

		  A short, simple shell script to make use
		  of bash-completion in order to fill in
		  DerpiGET's arguments

		  Please Note, the completion script is currently
		  in it's infancy and will only fill in arguments

		  DerpiGET's arguments are 'order sensitive' and
		  the completion script does NOT account for this." | sed 's/	//g'

	elif [ "$1" = "debugging" ]; then
		echo "debugging"
		echo -e "  How to see more details about DerpiGET's runs\n"

		echo -e "  This is controled by the environement variable: \$SILVERMOON_DEBUG"

		echo -e "  When \$SILVERMOON_DEBUG is NOT empty, DerpiGET will display debug messages.\n"

		echo "  Example uses:"
		echo -e "    SILVERMOON_DEBUG=1 ./derpiget.sh\n    export SILVERMOON_DEBUG=1; derpiget.sh"
	else
		echo "Topic \"$1\" does not exist."
	fi
}

function derpiget_splash {
	#Output a Ditzy "Derpy Hooves" Doo quote based on the clock
	#Special thanks to http://mlp.wikia.com/wiki/Derpy for the quotes
	if [ "$(date +%S)" -lt "10" ]; then
		echo "Muffin?"
	elif [ "$(date +%S)" -lt "20" ]; then
		echo "I just don't know what went wrong..!"
	elif [ "$(date +%S)" -lt "30" ]; then
		echo "Nice work, Rainbow Dash!"
	elif [ "$(date +%S)" -lt "40" ]; then
		echo "You okay, Rainbow Dash? Anything I can do to help?"
	elif [ "$(date +%S)" -lt "50" ]; then
		echo "Mr. Cake! Do you have any muffins today?"
	elif [ "$(date +%S)" -lt "60" ]; then
		echo "Mmm, muffins..."
	fi
}

function derpiget_automode {
	#For scripting
	#Added at the suggestion of Pouar
	robomode="true"

	if [ "$1" = "" ]; then
		derpiget_normal
	elif [ "$1" = "--shimmie" ]; then
		derpiget_shimmie
	elif [ "$1" = "--csvfix" ]; then
		derpiget_shimmie --csvfix
	elif [ "$1" = "--search" ]; then
		derpiget_search "$2"
	else
		echo -e "\e[31mInvalid Argument OR cannot be automated\e[0m"
		exit 1
	fi

}

function derpiget_csvomit {
	#Remove certain posts from list.csv
	loop=true
	end=$(cat list.csv | wc -l)
	if [ "$1" = "" ]; then
		line="1"
	else
		line="$1"
	fi
	while [ "$loop" = "true" ]; do
		clear
		echo "List.csv, Post: $line of $end."
		echo ""
		echo "File: $(cat list.csv | head -$line | tail -1 | cut -d"," -f 1 | sed 's/\"//g')"
		echo -n "Artist(s): "
		cat list.csv | head -$line | tail -1 | cut -d"," -f 2 | sed 's/\"//g' | tr ' ' '\n' | grep "artist:" | sed 's/artist://g' | head -3 | tr '\n' ' '
		echo -ne "\nTag(s): "
		cat list.csv | head -$line | tail -1 | cut -d"," -f 2 | sed 's/\"//g' | tr ' ' '\n' | grep -v "artist:" | head -4 | tr '\n' ' ' | sed 's/^ //g'
		echo ""
		echo -n "Source: "
		cat list.csv | head -$line | tail -1 | cut -d"," -f 3 | sed 's/\"//g'
		echo -e "\nw - Scroll Up   d - Scroll Down   j - Jump To   r - remove from list"
		echo "q - Quit"
		read -rsn1 KeyboardInput
		echo ""

		if [ "$KeyboardInput" = "w" ]; then
			if [ "$line" != "1" ]; then
				line=$(echo "$line - 1 " | bc)
			else
				line="$end"
			fi
		elif [ "$KeyboardInput" = "s" ]; then
			if [ "$line" != "$end" ]; then
				line=$(echo "$line + 1 " | bc)
			else
				line="1"
			fi
		elif [ "$KeyboardInput" = "j" ]; then
			echo -n "Jump to post: "
			read jumpto
			if [ "$jumpto" != "" ]; then
				if [ "$jumpto" -le "$end" ]&&[ "$jumpto" -gt "0" ]; then
					line="$jumpto"
				fi
			fi
		elif [ "$KeyboardInput" = "r" ]; then
			echo -n "Remove For sure? [Y/N] "
			read -rsn1 option
			if [ "$option" = "y" -o "$option" = "Y" ]; then
				tmpcsvrm=$(cat list.csv | head -$line | tail -1)
				tmpcsv=$(cat list.csv | grep -v "$tmpcsvrm")
				echo "$tmpcsv" > list.csv
				tmpfile=$(echo "$tmpcsvrm" | cut -d"," -f 1 | tr -d '"')
			fi
		elif [ "$KeyboardInput" = "q" ]; then
			echo -n "Are you sure? [Y/N] "
			read -rsn1 option
			if [ "$option" = "y" -o "$option" = "Y" ]; then
				exit
			fi
		fi

	done

}

function derpiget_csvremovelost {
	echo "This action will remove data from list.csv"
	echo "That corresponds to images that do not exist."
	echo ""
	echo -n "Continue? [Y/N] "
	read -rsn1 option
	echo -e "\n"
	if [ "$option" = "y" -o "$option" = "Y" ]; then
		#Get number of entries in list.csv
		lines=$(cat list.csv | wc -l)
		current=1
		#Load CSV into variable
		newcsv=$(cat list.csv)
		until [ "$current" -gt "$lines" ]; do
			lookfor=$(cat list.csv | head -$current | tail -1 | cut -d"," -f 1 | tr -d '"' | sed 's/bulkaddcsv\///g')
			if [ -a "$lookfor" ]; then
				echo -n ""
			else
				echo "Lost: $lookfor"
				newcsv=$(echo "$newcsv" | grep -v "bulkaddcsv/$lookfor")
			fi
			current=$(echo "$current + 1" | bc)
		done
		echo -ne "\nRemove entries and overwrite list.csv [Y/N] "
		read -rsn1 option
		echo -e "\n"
		if [ "$option" = "y" -o "$option" = "$Y" ]; then
			echo "$newcsv" > list.csv
		else
			echo "Aborted"
		fi
		exit
	else
		echo "Aborted"
		exit
	fi

}


function derpiget_changelog {
	dbgmsg "--function: derpiget_changelog--"
	echo "Possible Future Stuff
	-MAYBE Add Termux (Android) Support
	-Add a '--zip=FILE' option to zip images and list.csv
	-Add a '--strainer=FILE' option to utilize an alternative strainer file
	-Add a '--cookies=FILE' option to ustilize an alternative cookies.txt 
	-Add a '--dldir=DIR' option to utilize an alternative download directory

	v17.7.11 - The More Complete Update
	-Added '--csvremovelost' argument, removes missing images from list.csv
	-Added '--csvomit' option to remove entries from list.csv
	-Added '--changelog' option, so you can see what's new
	-Disabled '--csvomit' and '--csvremovelost' due to tagging issues
	-Replaced instances of 'which' with the POSIX 'command -v' (suggested by pouar)
	-Added optional audible alert to '--linksnoop' via 'beep' if 'beep' is available
	-Updated '--csvfix', will now download missing images
	-Updated '--linksnoop', no longer saves the same URLS with different parameters
	-Syntax for '--search' has changed to '--search=\"Query\"'
	-Syntax for '--about' has changed to '--about=\"Topic\"'
	-Overhauled Search Handler, arguments can now be used in ANY order you like
	-Added '--genbashcomplete' to output Bash Completion SCript for DerpiGET
	-Added some debug messages, visible when \$SILVERMOON_DEBUG has a value
	-Now uses 'file' instead of 'mimetype' removing dependancy on 'libfile-mimeinfo-perl'
	-Added Configuration Files to set preferences (see --about='derpiget.conf')
	-Added support for WebM in Mimetype detection
	-Add a '--mkconf' option to generate default config file in current directory
	-Add a '--config=FILE' option to utilize an alternative config file
	-Removed '-v' as an alias for '--version'
	-Moved config file reading to a more appropriate place in the script.

	v17.1.1 - The Arguments Update
	-Added New Default functionality downloads and names images based on tags
	-Added '--shimmie' argument, preforms original default functionality
	-Added '--search' argument for recording ALL search results
	-Added '--auto' argument for non-interactive mode
	-Added '--about' arugument for presenting more information
	-Added '--clear' argument for clearing cookies, leftovers, etc.
	-Added '--help' argument for listing arguments with basic summaries
	-Added '--version' argument to display version information
	-Added '--csvfix' argument for when list.csv has issues
	-Added '--linksnoop' argument to record post links you copy to your clipbard
	-Added Derpy Hooves Quotes
	-Added Super Pony Powers Easter Egg
	-Added better depdancy checking
	-Credit: Pouar (Suggesting a non-interactive mode)
	
	v16.11.17 - The Original
	-Created DerpiGET
	-No Support for Arguments
	-Downloads images to ./img/#
	-Creates Shimmie2 list.csv" | sed 's/^	//g' | less
}

function derpiget_genbashcomplete {
	echo '#!/bin/bash
#DerpiGET Completion
_DerpiGET ()
{
  local cur
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}

  case "$cur" in
    *)
    COMPREPLY=( $( compgen -W "--shimmie --csvfix --linksnoop --auto --search\= --config\= --mkconf --clear --about\= --version --help -? --changelog --genbashcomplete" -- $cur ) );;
  esac
  return 0
}
complete -F _DerpiGET ./derpiget.sh' > "derpiget_completion.sh"

	echo "Generated 'derpiget_completion.sh'
	Sourcing or adding the contents of this BASH Completion Script to your .bashrc
	Will allow the autocompleteion of DerpiGET arguments" | sed 's/^	//g'

}

function dbgmsg {
	#USE: dbgmsg MESSAGE
	if [ "$SILVERMOON_DEBUG" != "" ]; then
		echo -e "\e[33mDEBUG: $1\e[0m"
	fi
}

function derpiget_idfiletype {
	#Use: derpiget_idfiletype FILENAME
	#Used to replace functionality of the 'mimetype' command of 'libfile-mimeinfo-perl'
	#Added on February 11th, 2017
	#Special thanks to Pouar for helping me by suggesting [[ over [
	if [[ "$(file "$1" | cut -d':' -f 2)" == *"JPEG"* ]]; then
		echo "jpeg"
	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"PNG"* ]]; then
		echo "png"
	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"Targa"* ]]; then
		echo "tga"
	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"PC bitmap"* ]]; then
		echo "bmp"
	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"GIF"* ]]; then
		echo "gif"
	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"SVG"* ]]; then
		echo "svg"

	elif [[ "$(file "$1" | cut -d':' -f 2)" == *"WebM"* ]]; then
		echo "webm"


	else
		echo "file"
	fi
}

dbgmsg "--Functions Set--
Debug messages are enabled (\$SILVERMOON_DEBUG has non-empty value: $SILVERMOON_DEBUG)
Logging output via ./derpiget.sh 2>&1 | tee derpiget.log is recommended\n
If you believe you are seeing this message in error please be sure that the
environment variable \$SILVERMOON_DEBUG is NOT set.\n"

dbgmsg "--Dependancy Checking--"
#Dependancy checking
if [ "$(command -v bc)" = "" ]; then
	dependerr=$(echo -e "bc\n")
fi

if [ "$(command -v wget)" = "" ]; then
	dependerr=$(echo -e "$dependerr\nwget")
fi

if [ "$(command -v sed)" = "" ]; then
	dependerr=$(echo -e "$dependerr\nsed")
fi

if [ "$(command -v cut)" = "" ]; then
	dependerr=$(echo -e "$dependerr\ncut")
fi

if [ "$(command -v grep)" = "" ]; then
	dependerr=$(echo -e "$dependerr\ngrep")
fi

if [ "$(command -v wc)" = "" ]; then
	dependerr=$(echo -e "$dependerr\nwc")
fi

#if [ "$(command -v mimetype)" = "" ]; then
#	dependerr=$(echo -e "$dependerr\nmimetype")
#fi

if [ "$dependerr" != "" ]; then
	echo "Whoopsie! It looks like you're missing some commands that DerpiGET"
	echo "Needs to function!" 
	echo ""
	echo "(Is PATH set correctly? If so, you may need to install them)"
	echo "--Missing---------------------------------------------------------"
	echo "$dependerr"
	exit 1
fi

dbgmsg "--Arguement Handler--"
#NEW Arguement Handler
arg_function_count="0" #Set counter for function arguments
arg_invalid_count="0" #If higher than 0, exit with non-zero status
for arguement in "$@"; do
	#Set Variables
	abouttest=$(echo "$arguement" | cut -d'=' -f 1) #Used --about="Topic" ?
	searchtest=$(echo "$arguement" | cut -d'=' -f 1) #Used --search="Query" ?
	configtest=$(echo "$arguement" | cut -d'=' -f 1) #Used for --config="File" ?

	dbgmsg "ARG: $arguement"

	if [ "$searchtest" = "--search" ]; then
		#Handle Search
		arg_search="true"
		search="$(echo "$arguement" | sed 's/--search=//g')"
		if [ "$search" = "--search" ]; then
			search=""
		fi
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
	
	elif [ "$abouttest" = "--about" ]; then
		#Handle About
		arg_about="true"
		aboutentry="$(echo "$arguement" | sed 's/--about=//g')"
		if [ "$aboutentry" = "--about" ]; then
			aboutentry=""
		fi
		arg_incomp_robo="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)

	elif [ "$configtest" = "--config" ]; then
		#Handle Custom Config File use
		arg_config="true"
		configfile="$(echo "$arguement" | sed 's/--config=//g')"

	elif [ "$arguement" = "--auto" ]; then
		arg_auto="true"
	elif [ "$arguement" = "--shimmie" ]; then
		arg_shimmie="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
	elif [ "$arguement" = "--linksnoop" ]; then
		arg_linksnoop="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true" #Disallow --auto
	elif [ "$arguement" = "--changelog" ]; then
		arg_changelog="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true" #Disallow --auto
	elif [ "$arguement" = "--about" ]; then
		arg_about="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true"
	elif [ "$arguement" = "--genbashcomplete" ]; then
		arg_genbashcomplete="true"
		arg_incomp_robo="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
	elif [ "$arguement" = "--csvfix" ]; then
		arg_csvfix="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
	elif [ "$arguement" = "--clear" ]; then
		arg_clear="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true"
	elif [ "$arguement" = "--version" ]; then
		arg_version="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true"
	elif [ "$arguement" = "--help" -o "$arguement" = "-?" ]; then
		arg_help="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		arg_incomp_robo="true"

	elif [ "$arguement" = "--csvremovelost" ]; then
		arg_csvremovelost="true"
		arg_incomp_robo="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		echo "--csvremovelost"
		echo "Is disabled due to incorrect behavior"
		exit 1

	elif [ "$arguement" = "--csvomit" ]; then
		arg_csvomit="true"
		arg_incomp_robo="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		echo "--csvomit"
		echo "Is disabled due to incorrect behavior"
		exit 1

	elif [ "$arguement" = "--mkconf" ]; then
		#Argument Generates Config File, does not need later processing
		arg_mkconf="true"
		arg_function_count=$(echo "$arg_function_count + 1" | bc)
		echo -e "#Commented lines start with #\ndlpath:./img\nserverimgpath:bulkaddcsv/img\ncookies:./derpiget_cookies.txt\ndlcap:0" > ./derpiget.conf
		if [ "$robomode" != "true" ]; then
			echo "Generated ./derpiget.conf"
		fi
		exit
	elif [ "$argument" = "" ]; then
		#Literally no argument used
		echo -n ""

	else
		echo "Invalid Arguement: $arguement"
		arg_invalid_count=$(echo "$arg_invalid_count + 1" | bc)
	fi
done

#Check for Invalid Arguments
if [ "$arg_invalid_count" -gt "0" ]; then
	echo "You've used $arg_invalid_count Invalid Arguments"
	exit 1
fi

#Check for Invalid use of '--auto'
if [ "$arg_auto" = "true" -o "$robomode" = "true" ]&&[ "$arg_incomp_robo" = "true" ]; then
	echo "Incompatible Use of Non-Interactive Mode"
	echo ""
	echo "Non-Insteractive Mode only supports"
	echo "  ./derpiget.sh --auto"
	echo "  ./derpiget.sh --auto --shimmie"
	echo "  ./derpiget.sh --auto --search=\"Query\""
	echo "  ./derpiget.sh --auto --csvfix"
	echo ""
	exit 1
fi

#Check for invalid combinations of arguments
if [ "$arg_function_count" -gt "1" ]; then
	echo "Incompatible Arguments"
	echo ""
	echo "Please use only ONE of these at a time"
	echo "  --search=\"Query\""
	echo "  --help (or -?)"
	echo "  --about=\"Entry\""
	echo "  --genbashcomplete"
	echo "  --version (or -v)"
	echo "  --changelog"
	echo "  --shimmie"
	echo "  --csvfix"
	echo "  --linksnoop"
	echo "  --clear"
	exit 1
fi

#Enable Robomode if argument was received
if [ "$arg_auto" = "true" ]; then
	robomode="true"
fi

dbgmsg "--READ CONFIG--"

#Read CONFIG
if [ "$arg_config" = "true" ]; then
	if [ -e "$configfile" ]; then
		dbgmsg "Found $configfile, using it."
	else
		echo "Config File Not Found."
		exit 1
	fi
elif [ -e "./derpiget.conf" ]; then
	dbgmsg "Found ./derpiget.conf, using it."
	configfile="./derpiget.conf"
elif [ -e "$HOME/.derpiget.conf" ]; then
	dbgmsg "Found ~/.derpiget.conf, using it."
	configfile="$HOME/.derpiget.conf"
elif [ -e "/etc/derpiget.conf" ]; then
	dbgmsg "Found /etc/derpiget.conf, using it."
	configfile="/etc/derpiget.conf"
else
	dbgmsg "No Config files found."
	echo -n ""
fi

#Set Variables based on config
if [ "$configfile" != "" ];then
	dbgmsg "Config File: $configfile\n"
	configfilecontents="$(cat "$configfile" | grep -v "^#")"
	dlpath="$(echo "$configfilecontents" | grep "^dlpath:" | head -1 | cut -d':' -f 2-)"
	serverimgpath="$(echo "$configfilecontents" | grep "^serverimgpath" | head -1 | cut -d':' -f 2-)"
	cookies="$(echo "$configfilecontents" | grep "^cookies:" | head -1 | cut -d':' -f 2-)"
	dlcap="$(echo "cat $configfilecontents" | grep "^dlcap:" | head -1 | cut -d':' -f 2-)"

else
	if [ "$robomode" != "true" ]; then
		echo -e "No Config File, using default values\nSee ./derpiget.sh --about=\"config\" for details\n"
	else
		echo -n ""
	fi
fi

dbgmsg "\n--Configuration--\n\$dlpath=$dlpath\n\$serverimgpath=$serverimgpath\n\$cookies=$cookies\n\$dlcap=$dlcap\n-----------------"

#Set missing required options from config to default
if [ "$dlpath" = "" ]; then
	dlpath="./img"
fi
if [ "$serverimgpath" = "" ]; then
	serverimgpath="/derpiget"
fi
if [ "$cookies" = "" ]; then
	cookies="./cookies.txt"
fi
if [ "$dlcap" = "" ]; then
	dlcap=0
fi

#If image directory doesn't exist, make it
if [ ! -d "$dlpath" ]; then
	mkdir -p "$dlpath"
fi

#Use Pony Powers or display Splash Message if not in robomode
if [ "$robomode" != "true" ]&&[ "$1" != "--auto" ]; then
	if [ "$(command -v ponysay)" != "" ]; then
		if [ "$ponypower" = "activate" ]; then
			derpiget_splash | ponysay -f derpy
		else
			derpiget_splash
		fi
	else
		derpiget_splash
	fi
	echo ""
fi


#Decide what to do next
if [ "$arg_function_count" = "0" ]; then
	#No Function Arguments have been used, default functionality
	#Download Images Only
	derpiget_normal
	exit
elif [ "$arg_shimmie" = "true" ]; then
	#Create list.csv for Shimmie2's bulkaddcsv extention
	derpiget_shimmie
	exit
elif [ "$arg_csvfix" = "true" ]; then
	derpiget_shimmie --csvfix
	exit
elif [ "$arg_linksnoop" = "true" ]; then
	#Use XClip to check for copied post links
	if [ "$(command -v xclip)" = "" ]; then
		echo "Linksnoop relies on \"xclip\" to monitor"
		echo "your clipboard. You'll need it to use this"
		echo "functionality."
		exit 1
	fi
	derpiget_linksnoop
	exit
elif [ "$arg_search" = "true" ]; then
	derpiget_search "$search"
	exit
elif [ "$arg_clear" = "true" ]; then
	derpiget_clear
	exit
elif [ "$arg_changelog" = "true" ]; then
	derpiget_changelog
	exit
elif [ "$arg_help" = "true" ]; then
	help_message
	exit
elif [ "$arg_version" = "true" ]; then
	echo "DerpiGET Version"
	echo "  $scriptversion"
	exit
elif [ "$arg_genbashcomplete" = "true" ]; then
	derpiget_genbashcomplete
	exit
elif [ "$arg_about" = "true" ]; then
	derpiget_about "$aboutentry"
	exit
else
	#You should really never get here
	echo "How'd you manage this?"
	echo "The new argument handler doesn't support"
	echo "This section!"
	exit
fi