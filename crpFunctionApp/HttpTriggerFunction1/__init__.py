import logging
import json
import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info(f'HttpTriggerActions function processed a request. {req.headers.get("host")} {req.route_params} {req.params}')

    # The request path is set to the header queried below by custom resource provider
    # Ref: https://learn.microsoft.com/en-us/azure/azure-resource-manager/custom-providers/tutorial-custom-providers-function-authoring
    request_path = req.headers.get("X-MS-CustomProviders-RequestPath")

    logging.info(f"request_path: {request_path}")
    
    if req.method == "GET":
        # Check request_path to determine if the get request is for all resources or for requested resource
        get_all = True

        if(get_all == True):
            response = getResources(request_path)
        else:
            response = getResource(request_path)

        return func.HttpResponse(json.dumps(response), headers={'content-type':'application/json'}, status_code=200)

    elif req.method == "PUT":
        logging.info("Add Resource request")
        resource_name = "resource3"
        id = request_path
        body = req.get_json()
        response = createResource(id, resource_name, body)
        return func.HttpResponse(json.dumps(response), headers={'content-type':'application/json'}, status_code=200)

    elif req.method == "POST":
        logging.info("Action request")
        host = req.headers.get("host")
        body = req.get_json()
        content = { 'pingcontent' : { 'source' : host } , 'body': body, 'message' : 'hello ' + request_path + '|' + host}
        return func.HttpResponse(json.dumps(content), headers={'content-type':'application/json'}, status_code=200)

    elif req.method == "DELETE":
        logging.info("Delete Resource request")
        # !!!Delete the requested resource here!!!

        return func.HttpResponse(status_code=200)
    else:
        logging.info(f"Unsupported method {req.method}")
        func.HttpResponse("Unsupported method", status_code=405)

    # else:
    #     # Action not known
    #     return func.HttpResponse({"msg": "Invalid action"}, headers={'content-type':'application/json'}, status_code=200)


# Returns list of all resources
def getResources(requestPath):

    return {
        "value": [
            {
            "id": requestPath + "/resource1",
            "name": "resource1"
            },
            {
            "id": requestPath + "/resource2",
            "name": "resource2"
            }
        ]
    }

# Returns the requested resource
def getResource(requestPath):

    requested_resource_name = requestPath;

    return {
        "id": requestPath + "/" + requested_resource_name,
        "name": requested_resource_name
        }

def createResource(id, resourceName, body):

    new_resource = {
            "id": id,
            "name": "resourceName"
            }

    return new_resource
