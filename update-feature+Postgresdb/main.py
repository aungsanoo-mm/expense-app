from app import app

if __name__ == "__main__":
    import os
    import logging
    logging.basicConfig(level=logging.DEBUG)
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
