from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    docker_logo = ' \U0001F433'  # Docker logo Unicode character
    return 'Hello let\'s learn docker' + docker_logo

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
