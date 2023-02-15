docker_compose("./docker-compose.yml")

# Set every service which does not restart to be manually triggered, because its a one off task
for service, values in read_yaml("./docker-compose.yml")['services'].items():
    if 'restart' not in values:
        dc_resource(service, trigger_mode=TRIGGER_MODE_MANUAL,  auto_init=False)

load('ext://dotenv', 'dotenv')
dotenv()

hostname = os.getenv('HOSTNAME')

dc_resource("web", links=[link(hostname, "home"), link(hostname + "/logs", "logs")])
dc_resource("glitchtip-web", links=[link("glitchtip." + hostname, "Glitchtip")])


# If we are not in the production docker context, disable ddclient
current_context = str(local("docker context inspect -f '{{.Name}}'", quiet=True)).strip()
production_context = os.getenv("PRODUCTION_CONTEXT")
in_production = current_context == production_context
print("In production: " + str(in_production))
if not in_production:
    dc_resource("ddclient", trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
