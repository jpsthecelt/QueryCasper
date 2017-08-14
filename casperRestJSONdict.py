import requests
import xmltodict
import json

user = 'yourusername'
pwd = 'yourpwd'
OK = 200

url = 'https://yourjsshere:8443/JSSResource/'

r = requests.get(url+'mobiledevices', verify=False, auth=(user,pwd), headers={'Accept': 'application/json'})

if r.status_code != OK:
   print('Uh-oh, status code is: ', r.status_code)
   exit()
else:
    print(json.loads(json.dumps(r.text)))
#   print(r.text['mobile_devices'])

exit()

newDict = xmltodict.parse(r.text)['mobile_devices']['mobile_device']

m = []
n = []

print "\n\n"
for f in newDict:
   n.append(f['name'])
   m.append(f['model'])
   print 'Username: %s, Name: %s, Model: %s' % (f['username'],f['name'],f['model'])

