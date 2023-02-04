# Copy web to init service which runs init script
dc_file = read_yaml("./docker-compose.yml")

web_service = dc_file['services']['web']
web_service['command'] = 'init.sh'

docker_compose(["./docker-compose.yml", encode_yaml({"services": {"init": web_service}})])
dc_resource("init", trigger_mode=TRIGGER_MODE_MANUAL)
dc_resource("glitchtip-migrate", trigger_mode=TRIGGER_MODE_MANUAL)

load('ext://dotenv', 'dotenv')
dotenv()

hostname = os.getenv('HOSTNAME')


dc_resource("web", links=[link(hostname, "home"), link(hostname + "/logs", "logs")])
