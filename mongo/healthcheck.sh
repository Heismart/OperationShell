#############################################################################
# Don't make any changes to this script                                     #
# File :    mongo_health_report.sh                                          #
# Purpose : The purpose of this script is to report Database health check   #
#                                                                           #
# History:                                                                  #
# Name                   Date                                Version        #
# ***********************************************************************   #
# MongoDB Health Script                                       1.0.0         #
#############################################################################
#! /bin/bash
#Checking if this script is being executed as ROOT. For maintaining proper directory structure, this script must be run from a root user.
if [ $EUID != 0 ]; then
    echo "Please run this script as root so as to see all details! Better run with sudo."
    exit 1
fi

#Declaring variables
#set -x
MYUSER=root
MYPASS=
#REPORT_TO="<your_REPORT_TOress>"
REPORT_TO=

# Collecting ENV information
checking_date=$(date)
hstname=$(hostname)
ip_add=$(ip addr | grep "inet" | head -2 | awk {'print$2'} | cut -f2 -d:)

# Checking instance stat
UP1=$(service mongod status)
if [ "$?" -gt "0" ]; then
    INSTSTAT=("MongoDB Not Running")
else
    INSTSTAT=("MongoDB Running")
fi

# Checking metries of instance 
upt=$(mongo --quiet --eval "db.serverStatus().uptime / 86400")
sr_version=$(mongod -version | awk 'FNR== 1 {print $3}')
strg_engine=$(mongo --quiet --eval "db.serverStatus().storageEngine" | awk -F'[, ]' 'FNR== 2 {print $3}')
curr_conn=$(mongo --quiet --eval "db.serverStatus().connections" | awk -F'[, ]' {'print $4'})
avi_conn=$(mongo --quiet --eval "db.serverStatus().connections" | awk -F'[, ]' {'print $8'})
total_cre=$(mongo --quiet --eval "db.serverStatus().connections" | awk {'print $10'})
list_db=$(mongo --eval "db.getMongo().getDBNames()" | awk 'FNR == 4' | awk ' { gsub ( /[][]/, "" ) ;  print }')
reglr=$(mongo --quiet --eval "db.serverStatus().asserts" | awk -F'[, ]' {'print $4'})
warng=$(mongo --quiet --eval "db.serverStatus().asserts" | awk -F'[, ]' {'print $8'})
msg=$(mongo --quiet --eval "db.serverStatus().asserts" | awk -F'[, ]' {'print $12'})
usr=$(mongo --quiet --eval "db.serverStatus().asserts" | awk -F'[, ]' {'print $16'})
rollovr=$(mongo --quiet --eval "db.serverStatus().asserts" | awk -F'[, ]' {'print $20'})
load_avg=$(cat /proc/loadavg | awk {'print$1,$2,$3'} | sed 's/ /,/g')
ram_usage=$(free -m | head -2 | tail -1 | awk {'print$3'})
ram_total=$(free -m | head -2 | tail -1 | awk {'print$2'})
mem_pct=$(free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }')
mnt_pnt=$(df -h | awk 'FNR==4')

# Creating a directory if it doesn't exist to store reports first, for easy maintenance.
if [ ! -d ${HOME}/health_reports ]; then
    mkdir ${HOME}/health_reports
fi
find ${HOME}/health_reports/ -mtime +1 -exec rm {} \;
html="${HOME}/health_reports/MongoDB-Health-Report-$(hostname)-$(date +%y%m%d)-$(date +%H%M).html"

for i in $(ls /home); do sudo du -sh /home/$i/* | sort -nr | grep G; done >/tmp/dir.txt
# Generating HTML file
echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">" >>$html
echo "<html>" >>$html
echo "<link rel="stylesheet" href="https://unpkg.com/purecss@0.6.2/build/pure-min.css">" >>$html
echo "<body bgcolor="A4F097">" >>$html
echo "<fieldset>" >>$html
echo "<center>" >>$html
echo "<h2><u>MongoDB Server Health Report</u></h2>" >>$html
echo "<h4><legend>Version 1.0</legend></h4>" >>$html
echo "</center>" >>$html
echo "</fieldset>" >>$html
echo "<br>" >>$html
echo "<center>" >>$html
############################################MongoDB Instance Details#######################################################################
echo "<h3><u>MongoDB Instance Details</u> </h3>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th>Hostname</th>" >>$html
echo "<th>IP Address</th>" >>$html
echo "<th>Instance Status</th>" >>$html
echo "<th>Server Version</th>" >>$html
echo "<th>Storage Engine</th>" >>$html
echo "<th>Uptime in Days</th>" >>$html
echo "<th>Date & Time</th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td>$hstname</td>" >>$html
echo "<td>$ip_add</td>" >>$html
echo "<td><font color="Red">$INSTSTAT</font></td>" >>$html
echo "<td>$sr_version</td>" >>$html
echo "<td>$strg_engine</td>" >>$html
echo "<td>$upt</td>" >>$html
echo "<td>$checking_date</td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
############################################MongoDB Connection Details#######################################################################
echo "<h3><u>MongoDB Connection Details</u> </h3>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th>Current Connection</th>" >>$html
echo "<th>Available Connection</th>" >>$html
echo "<th>Total created Connection</th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td>$curr_conn</td>" >>$html
echo "<td>$avi_conn</td>" >>$html
echo "<td>$total_cre</td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
########################################### MongoDB Asserts Status #######################################################################
echo "<h3><u>MongoDB Asserts Status</u> </h3>" >>$html
echo "<br>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th>Regular</th>" >>$html
echo "<th>Warning</th>" >>$html
echo "<th>Msg</th>" >>$html
echo "<th>User</th>" >>$html
echo "<th>Rollovers</th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td><center>$reglr</center></td>" >>$html
echo "<td><center>$warng</center></td>" >>$html
echo "<td><center>$msg</center></td>" >>$html
echo "<td><center>$usr</center></td>" >>$html
echo "<td><center>$rollovr</center></td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
########################################### MongoDB Instance Databases List #######################################################################
echo "<h3><u>MongoDB Instance Databases List</u> </h3>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th><center>Databases List</center></th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td>$list_db</td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
echo "<br />" >>$html
echo "</table>" >>$html
echo "</body>" >>$html
echo "</html>" >>$html
########################################### Resource Status #######################################################################
echo "<h3><u>Resource Utilization</u> </h3>" >>$html
echo "<br>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th>Load Average</th>" >>$html
echo "<th>Used RAM(in MB)</th>" >>$html
echo "<th>Total RAM(in MB)</th>" >>$html
echo "<th>Memory Utilization %</th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td><center>$load_avg</center></td>" >>$html
echo "<td><center>$ram_usage</center></td>" >>$html
echo "<td><center>$ram_total</center></td>" >>$html
echo "<td><center>$mem_pct</center></td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
########################################### Disk Utilization #######################################################################
echo "<h3><u>Disk Utilization</u> </h3>" >>$html
echo "<table class="pure-table">" >>$html
echo "<thead>" >>$html
echo "<tr>" >>$html
echo "<th><center>Mount Point Usage</center></th>" >>$html
echo "</tr>" >>$html
echo "</thead>" >>$html
echo "<tbody>" >>$html
echo "<tr>" >>$html
echo "<td>$mnt_pnt</td>" >>$html
echo "</tr>" >>$html
echo "</tbody>" >>$html
echo "</table>" >>$html
echo "<br />" >>$html
echo "</table>" >>$html
echo "</body>" >>$html
echo "</html>" >>$html

#Sending Email to the user
if [ ! -n "$REPORT_TO" ]; then
    echo "Report has been generated in ${HOME}/health_reports with file-name = $html. "
else
    mailx -a $html -s "MongoDB Health Report" $REPORT_TO </dev/null
    echo "Report has also been sent to $REPORT_TO."
fi
