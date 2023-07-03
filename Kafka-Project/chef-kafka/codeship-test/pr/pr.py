import requests
import os
import re 
import json
from requests.auth import HTTPBasicAuth

jira_endpoint="jira-ext.odesk.com"

jira_user= os.environ.get('jira_user')
jira_password= os.environ.get('jira_password')
issue=""
link_list=[]
CI_REPO_NAME= os.environ.get('CI_REPO_NAME') 
CI_BRANCH = os.environ.get('CI_BRANCH') 
CI_PR_NUMBER = os.environ.get('CI_PR_NUMBER') 
CI_COMMIT_MESSAGE = os.environ.get('CI_COMMIT_MESSAGE') 
CI_PULL_REQUEST = os.environ.get('CI_PULL_REQUEST') 
CI_PR__LINK_TEXT="%s(PR_%s)" % (CI_REPO_NAME,CI_PR_NUMBER)
CI_BRANCH_LINK_TEXT = "%s(Branch_%s)" % (CI_REPO_NAME,CI_BRANCH)


def parseIssue():
    try:
        return re.search("^(.*?)-\S\w*",CI_COMMIT_MESSAGE.lstrip(' ')).group(0)
    except:
        return 0
    

def issue_error_exist():
    issue_id=requests.get('https://'+jira_endpoint+'/rest/api/latest/issue/'+issue+'/remotelink', auth=HTTPBasicAuth(jira_user, jira_password))
    print (issue_id.text)
    print (issue_id.status_code)
    return issue_id.status_code

def list_links():
    links=requests.get('https://'+jira_endpoint+'/rest/api/latest/issue/'+issue+'/remotelink', auth=HTTPBasicAuth(jira_user, jira_password))
    print (links.text)
    json_data = json.loads(links.text)
    for i in json_data:
        link_example = {
            "ticket": i["object"]["title"],
            "url": i["object"]["url"]
        }
        link_list.append(link_example)

def add_PR(PR):
    data={
    "object": {
        "url":CI_PULL_REQUEST,
        "title":CI_PR__LINK_TEXT
        }
    }
    print(data)
    print ("add PR"+str(PR))
    r=requests.post('https://'+jira_endpoint+'/rest/api/latest/issue/'+issue+'/remotelink', json = data, auth=HTTPBasicAuth(jira_user, jira_password)) 
    print (r)
        
def lookup_PR():
    f=0
    for i in link_list:
        if i["ticket"]==CI_PR__LINK_TEXT:
            f=1
    if (f == 0):        
        add_PR(CI_PR_NUMBER)

def lookup_Branch():
    f=0
    for i in link_list:
        if i["ticket"]==CI_BRANCH_LINK_TEXT:
            f=1
    if (f == 0):        
        add_branch(CI_BRANCH)

def add_branch(branch):
    data_branch={
    "object": {
        "url":"https://github.com//"+CI_REPO_NAME+"/tree/"+branch,
        "title": CI_BRANCH_LINK_TEXT
        }
    }
    print(data_branch)
    print (issue)
    print ("add Branch"+str(branch))
    r=requests.post('https://'+jira_endpoint+'/rest/api/latest/issue/'+issue+'/remotelink', json = data_branch, auth=HTTPBasicAuth(jira_user, jira_password)) 
    print (r)

#### MAIN  FLOW  #####

issue=parseIssue()
if issue != 0 and issue_error_exist() == 200:
    list_links()
    lookup_PR()
    lookup_Branch()
    list_links()
    print(link_list)
