docker_compose("./docker-compose.yml")

# Set every service which does not restart to be manually triggered, because its a one off task
# This way they will only run on the first start
for service, values in read_yaml("./docker-compose.yml")['services'].items():
    if 'restart' not in values:
        dc_resource(service, trigger_mode=TRIGGER_MODE_MANUAL)

load('ext://dotenv', 'dotenv')
dotenv()

hostname = os.getenv('HOSTNAME')

dc_resource("web", links=[link(hostname, "home"), link(hostname + "/logs", "logs")])
dc_resource("glitchtip-web", links=[link("glitchtip." + hostname, "Glitchtip")])


# If the user is not the production user, disable the ddclient service
user = os.getenv("USER")
production_user = os.getenv("PRODUCTION_USER")
if user != production_user:
    dc_resource("ddclient", trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
