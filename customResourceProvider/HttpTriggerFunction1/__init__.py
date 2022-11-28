import logging

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info(f'HttpTriggerActions function processed a request. {req.headers.get("host")} {req.route_params} {req.params}')
    logging.debug(f"host: {req.headers}")

    # Route ends with {actions}/{name}
    # action can be "action" with "name" set to name of action or "servers" with name set to server resource name. 
    # action = req.route_params.get('action')
    action = "action"
    # action_name = req.route_params.get('name')
    action_name = "action_name"
    # The request path is set to the header queried below by custom resource provider
    # Ref: https://learn.microsoft.com/en-us/azure/azure-resource-manager/custom-providers/tutorial-custom-providers-function-authoring
    request_path = req.headers.get("X-MS-CustomProviders-RequestPath")

    # # POST a ping action 
    # if action == "action":
    #     logging.debug(f"action: {action_name}")
    #     if req.method == 'POST':
    #         # get host
    #         host = req.headers.get("host")
    #         content = { 'pingcontent' : { 'source' : host } , 'message' : 'hello ' + action_name + '|' + host}
    #         logging.debug(f"content: {content}")
    #         return func.HttpResponse(json.dumps(content), headers={'content-type':'application/json'}, status_code=200)
    #     else:
    #         return func.HttpResponse({"msg": "Method not allowed!"}, headers={'content-type':'application/json'}, status_code=401)
    # logging.debug("action: servers")
    # resource_name = req.route_params.get('name')
    resource_name = "serverz"
    if req.method == "GET":
        # Commented the below code temporarily untill I figure out distinguishing between GET request for getresource and getresources.
        # # Like https://redefinitbma3func.azurewebsites.net/api/servers/{resource_name}
        # logging.info("Get Resource request")
        # resource = getResource(request_path, resource_name)
        # return func.HttpResponse(json.dumps(resource), headers={'content-type':'application/json'}, status_code=200)

        resources = getResources(request_path)
        return func.HttpResponse(json.dumps(resources), headers={'content-type':'application/json'}, status_code=200)

    elif req.method == "PUT":
        logging.info("Add Resource request")
        id = request_path
        body = req.get_json()
        return createResource(id, resource_name, body)
    elif req.method == "POST":
        logging.info("Action request")
        # get host
        host = req.headers.get("host")
        content = { 'pingcontent' : { 'source' : host } , 'message' : 'hello ' + request_path + '|' + host}
        logging.debug(f"content: {content}")
        return func.HttpResponse(json.dumps(content), headers={'content-type':'application/json'}, status_code=200)
    elif req.method == "DELETE":
        logging.info("Delete Resource request")
        return deleteResource(request_path, resource_name)
        # return func.HttpResponse("Unhandled method", status_code=405)
    else:
        logging.info(f"Unsupported method {req.method}")
        func.HttpResponse("Unsupported method", status_code=405)

    # else:
    #     # Action not known
    #     return func.HttpResponse({"msg": "Invalid action"}, headers={'content-type':'application/json'}, status_code=200)
