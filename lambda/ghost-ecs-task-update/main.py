import json
import os
import boto3


r53_client = boto3.client('route53')
# ec2_client = boto3.client('ec2')
ec2_resource = boto3.resource("ec2")



def handler(event, context):
    print('Received event: ' + json.dumps(event, indent=2))

    detail = event['detail']
    if not detail['lastStatus'] == "RUNNING" and detail['desiredStatus'] == 'RUNNING':
        print("not ready")
        return



    net_details = detail['attachments'][0]['details']

    print("net_details")
    print(net_details)

    eni_id = [i["value"] for i in net_details if i["name"] == "networkInterfaceId"][0]
    print("eni_id")
    print(eni_id)

    eni = ec2_resource.NetworkInterface(eni_id)
    print(eni)

    public_ip = eni.association_attribute["Public_ip"]
    print(public_ip)


    res = r53_client.change_resource_record_sets(
        HostedZoneId=os.environ["HOSTED_ZONE_ID"],
        ChangeBatch={
            "Comment": "Automatic DNS update",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": os.environ["RECORD_NAME"],
                        "Type": "CNAME",
                        "TTL": 5,
                        "ResourceRecords": [
                            {
                                "Value": public_ip
                            },
                        ],
                    }
                },
            ]
        }
    )
    print("done")
    print(res)
