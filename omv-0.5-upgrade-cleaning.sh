#/!bin/bash
## Cleaning script to update OMV savely from 0.4 to 0.5

# R. Lindlein aka Solo0815 in the OMV-Forums
# v 0.8.0

# Bugs fixed / features added:
# - typo
# - added removing js-files from jhmiller's script
# - one date to rule them all ;)
# - creating directory - forget variable (stupid me)
# - only external plugins are removed
# - fixed error in the rename *.js-files section
# - added purging of the website plugin and omv-plugins.org
# - added moving millers.list because the containing linux-mint entries it gave errors with OMV 0.5 
# - added removing other stuff from http://forums.openmediavault.org/viewtopic.php?f=14&t=2262&start=10#p15824
# - moved from sh to bash -> should resolve some errors with [[ ]]
# - added code to get local.list back
###########################################################################################
### Variables

# import OMV-variables
. /etc/default/openmediavault

# Sample - possible usefull variables
# OMV_DPKGARCHIVE_DIR="/var/cache/openmediavault/archives"
# OMV_DOCUMENTROOT_DIR="/var/www/openmediavault"
# OMV_CACHE_DIR="/var/cache/openmediavault"

SCRIPTDATE="$(date +%y%m%d-%H%M%S)"
TITLE="Clean OMV to upgrade from 0.4 to 0.5"
BACKTITLE="OMV-Upgrade-Cleaner"
OMVFOLDER_DEBS="/root/omv0.4_cleaning_for_0.5/"
OMVLOGFILE="/root/omv-0.5-cleaning_${SCRITPDATE}.log"
OMVAPT="/etc/apt/sources.list.d"
OLDJSEXT="_omv0.4_$SCRIPTDATE"

###########################################################################################
### Functions
f_aborted() {
	whiptail --title "Script cancelled" --backtitle "${BACKTITLE}" --msgbox "         Aborted!" 7 32
	exit 0
}

# simple log-output
f_log() {
	echo "$1" >> $OMVLOGFILE
	echo "$1"
}

###########################################################################################
### Begin of script

echo

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --msgbox "This script will clean your OMV-Installation, so that you can upgrade from 0.4 to 0.5\n\nPlease read the following instructions carefully!" 11 78

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "To clean up your OMV-installation, the following steps are required:\n1. remove all external plugins.\n   The config is still there\n2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module and admin/\n3. move all *.deb files and local.list in $OMVAPT/\n4. move old-omvplugins.org-lists\n\nDo you want to do this?" 15 78
[[ $? = 0 ]] || f_aborted

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "You are using this script at your own risk!\n\nAre you ready to reinstall OMV if something goes wrong or this script isn't working as expected?" 11 78
[[ $? = 0 ]] || f_aborted

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "You know, what you are doing?\n\nLogfile is $OMVLOGFILE" 8 78
[[ $? = 0 ]] || f_aborted

f_log "Cleaning started - $SCRIPTDATE"
f_log ""

### 1. remove all external plugins
f_log "1. remove all non- OMV-plugins"
PLUGINSTOREMOVE=$(apt-cache search openmediavault- | awk '{print $1}'| egrep -v 'openmediavault-(clamav|forkeddaapd|iscsitarget|keyring|ldap|lvm2|netatalk|nut|route|usbbackup)')

if [ "$PLUGINSTOREMOVE" = "" ]; then 
	f_log "There are no external PlugIns installed! Nothing to do here!"
else
	f_log "PlugIns to remove:"
	f_log "$PLUGINSTOREMOVE"
	f_log "Working ..."

	# Website-Plugin has to be purged
	if echo "$PLUGINSTOREMOVE" | egrep 'openmediavault-website'; then
		f_log "removing OMV-Website Plugin ... --purge"
		apt-get remove --purge -y -q openmediavault-website >> $OMVLOGFILE
	fi

	if echo "$PLUGINSTOREMOVE" | egrep 'openmediavault-omvpluginsorg'; then
		f_log "removing openmediavault-omvpluginsorg ... --purge"
		apt-get remove --purge -y -q openmediavault-omvpluginsorg >> $OMVLOGFILE
	fi
	
	f_log "removing normal PlugIns ..."
	PLUGINSTOREMOVE_new="$(echo "$PLUGINSTOREMOVE" | egrep -v 'openmediavault-website|omv-plugins.org')"
	apt-get remove -y -q $PLUGINSTOREMOVE_new >> $OMVLOGFILE
fi
sleep 1
f_log ""

### 2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"
f_log "2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"
if [ -f $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/*.js ]; then
	f_log "Your folder for js-files:"
	ls $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/*.js >> $OMVLOGFILE
	for OLDJSFILES in "$OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"*.js; do
		mv "${OLDJSFILES}" "${OLDJSFILES}${OLDJSEXT}" && f_log "$OLDJSFILES renamed to ${OLDJSFILES}${OLDJSEXT}"
	done
else
	f_log "No old js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin found. Nothing to do here!"
fi
sleep 1
f_log ""

### 2a. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/
f_log "2a. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/"
if [ -f $OMV_DOCUMENTROOT_DIR/js/omv/module/*.js ]; then
	f_log "Your folder for js-files:"
	ls $OMV_DOCUMENTROOT_DIR/js/omv/module/*.js >> $OMVLOGFILE
	for OLDJSFILES in "$OMV_DOCUMENTROOT_DIR/js/omv/module/"*.js; do
		mv "${OLDJSFILES}" "${OLDJSFILES}${OLDJSEXT}" && f_log "$OLDJSFILES renamed to ${OLDJSFILES}${OLDJSEXT}"
	done
else
	f_log "No old js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module found. Nothing to do here!"
fi
sleep 1
f_log ""

### 3. move all *.deb files in $OMVFOLDER_DEBS
f_log "3. move all *.deb and openmediavault-local.list in $OMVAPT/"

if [ ! -d $OMVFOLDER_DEBS ]; then 
	mkdir $OMVFOLDER_DEBS && f_log "$OMVFOLDER_DEBS created"
else
	f_log "folder $OMVFOLDER_DEBS already exists!"
fi

if ls $OMV_DPKGARCHIVE_DIR/*.deb >/dev/null 2>&1; then
	mv $OMV_DPKGARCHIVE_DIR/*.deb $OMVFOLDER_DEBS && f_log "moved all manually installed *.deb-files to $OMVFOLDER_DEBS"
else
	f_log "No old deb-files in $OMV_DPKGARCHIVE_DIR found. Nothing to do here!"
fi

if ls $OMVAPT/openmediavault-local.list >/dev/null 2>&1; then
	mv $OMVAPT/openmediavault-local.list $OMVFOLDER_DEBS && f_log "moved $OMVAPT/openmediavault-local.list to $OMVFOLDER_DEBS"
	echo "deb file:$OMV_CACHE_DIR/archives /" > $OMVAPT/openmediavault-local.list && f_log "created a new $OMVAPT/openmediavault-local.list"
else
	f_log "No file: $OMVAPT/openmediavault-local.list found. Nothing to do here!"
fi
sleep 1
f_log ""


### 4. move old-omvplugins.org-lists
f_log "4. move old-omvplugins.org-lists in $OMVAPT/"
if [ -f $OMVAPT/omv-plugins-org-* ]; then
	mv $OMVAPT/omv-plugins-org-* $OMVFOLDER_DEBS && f_log "moved old omvplugins.org-lists in $OMVAPT/ to $OMVFOLDER_DEBS"
else
	f_log "No old lists for omvplugins.org found in $OMVAPT/omv-plugins-org-* found. Nothing to do here!"
fi

if [ -f $OMVAPT/openmediavault-millers.list ]; then
	mv $OMVAPT/openmediavault-millers.list $OMVFOLDER_DEBS && f_log "moved openmediavault-millers.list in $OMVAPT/ to $OMVFOLDER_DEBS"
else 
	f_log "No openmediavault-millers.list found in $OMVAPT. Nothing to do here!"
fi
sleep 1
f_log ""

### 5. clean other stuff
# from thread: http://forums.openmediavault.org/viewtopic.php?f=14&t=2262&start=10#p15824
f_log "5. Clean other stuff"
if [ -f /etc/apache2/openmediavault-webgui.d/git.conf ]; then
	mv /etc/apache2/openmediavault-webgui.d/git.conf $OMVFOLDER_DEBS && f_log "moved git.conf in /etc/apache2/openmediavault-webgui.d/ to $OMVFOLDER_DEBS"
fi
if [ -f /etc/apache2/mods-enabled/authnz_external.load ]; then
	mv /etc/apache2/mods-enabled/authnz_external.load $OMVFOLDER_DEBS && f_log "moved authnz_external.load in /etc/apache2/mods-enabled/ to $OMVFOLDER_DEBS"
fi
sleep 1
f_log ""

f_log "The cleaning of OMV 0.4 for upgrading to 0.5 was successfull! Please reboot. Then you can upgrade to 0.5 at your own risk via \"omv-release upgrade\""
echo
echo "The logfile is $OMVLOGFILE"

exit 0