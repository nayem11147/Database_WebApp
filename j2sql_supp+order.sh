#!/bin/bash
#          
#  Write below your own credentials
user="u15"
pass="23tearMOTHERtrack41"
db="u15"
#
echo
# 
# Read the JSON file into a variable
json_data=$(<orders_4000.json)

# Extract data for orders table
when=$(echo "$json_data" | grep -o '"when":"[^"]*' | sed 's/"when":"//')
supp_id=$(echo "$json_data" | grep -o '"supp_id":[0-9]*' | awk -F ":" '{print $2}')

# Create JSON file for orders table
echo "{\"when\":\"$when\",\"supp_id\":$supp_id}" > orders.json

# Extract data for order_items table
items=$(echo "$json_data" | grep -o '"items":\[[^]]*' | sed 's/"items"://')

# Create JSON file for order_items table
echo "$items" > order_items.json

# Read the JSON file into a variable
json_data=$(<suppliers_100.json)

# Extract data for suppliers table
supplier_id=$(echo "$json_data" | grep -o '"_id":[0-9]*' | awk -F ":" '{print $2}')
supplier_name=$(echo "$json_data" | grep -o '"name":"[^"]*' | sed 's/"name":"//')
supplier_email=$(echo "$json_data" | grep -o '"email":"[^"]*' | sed 's/"email":"//')

# Create JSON file for suppliers table
echo "{\"s_id\":$supplier_id,\"name\":\"$supplier_name\",\"email\":\"$supplier_email\"}" > suppliers.json

# Extract data for supplier_tel table
tel_numbers=$(echo "$json_data" | grep -o '"number":"[^"]*' | sed 's/"number":"//' | tr '\n' ',')
tel_numbers=${tel_numbers::-1} # Remove the trailing comma

# Create JSON file for supplier_tel table
echo "{\"supp_id\":$supplier_id,\"tel_number\":\"$tel_numbers\"}" > supplier_tel.json

mongoimport -d "$db" -c suppliers -u "$user" --password="$pass" --type="json" --file="suppliers.json"
mongoexport -d "$db" -c suppliers -u "$user" -p "$pass" --type=csv --fields "_id,name,email" | tail -n +2 > suppliers.csv
mongoimport -d "$db" -c supplier_tel -u "$user" --password="$pass" --type="json" --file="supplier_tel.json"
mongoexport -d "$db" -c supplier_tel -u "$user" -p "$pass" --type=csv --fields "_id,number" | tail -n +2 > supplier_tel.csv
mongoimport -d "$db" -c orders -u "$user" --password="$pass" --type="json" --file="orders.json"
mongoexport -d "$db" -c orders -u "$user" -p "$pass" --type=csv --fields "when,supp_id" | tail -n +2 > orders.csv
mongoimport -d "$db" -c order_items -u "$user" --password="$pass" --type="json" --file="order_items.json"
mongoexport -d "$db" -c order_items -u "$user" -p "$pass" --type=csv --fields "part_id,qty" | tail -n +2 > order_items.csv
#
echo "source make_tables.sql;" | mysql -u "$user" --password="$pass" "$db"
cat suppliers.csv  | tr "," "\t" > suppliers.tsv
echo "load data local infile 'suppliers.tsv' into table suppliers" | mysql $db -u $user --password="$pass"
cat supplier_tel.csv  | tr "," "\t" > supplier_tel.tsv
echo "load data local infile 'supplier_tel.tsv' into table supplier_tel" | mysql $db -u $user --password="$pass"
cat orders.csv  | tr "," "\t" > orders.tsv
echo "load data local infile 'orders.tsv' into table orders" | mysql $db -u $user --password="$pass"
cat order_items.csv  | tr "," "\t" > order_items.tsv
echo "load data local infile 'order_items.tsv' into table order_items" | mysql $db -u $user --password="$pass"
echo
