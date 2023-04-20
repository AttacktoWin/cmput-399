# RPS Dungeons Research Project

This is the source code for the RPS Dungeons research study, co-authored by Jawdat Toume and Shashank Bhat. The front-end is written in Godot 3.5 and the API for the back-end is written in Python. Not provided is the source code for the back-end environment including the models.

## Getting Started

To run the project, add the RPS Dungeons environment code to the Server/src folder. Ensure that the code is using the `Shashank` branch. You may also need to change `adapter.__init__()` to pull models from `src/files` as the webserver code will be in the parent folder. To start the websever, run `python websocket.py` from within the Server folder. To run the Godot project, launch the project found in the root directory with Godot 3.5 and press the Play button. When exporting the project ensure you change the `survey_url` in State.gd as well as the `websocket_url` in Client.gd. To export the Godot project to html, go to `Project->Export...` in the Godot editor and export using the HTML template. The exported files will be in the Bin folder.

## Notes

The websever is used to host adapaters for each participant and figure out which strategy that participant is using. It also logs data to the Server/logs folder. It still needs a bit of code to determine whether to use the control agent or the adaptive agent (look at the TODO comment in `websocket.py` for more information).

The Godot side handles much more of the code, with the majority of it held in State.gd. Of note within State.gd is the `resolve_state()` method. It is currently based off of the `State.resolve()` method found in the RPS Dungeons environment but this has been known to cause issues such as units stacking on top of each other. This method needs to change before studies are run though be warned that since the method is based off of the method used in training the models, changing one without changing the other may lead to issues with the models. 

To host this, you can run the websocket on a machine with port 5015 forwarded. Get the ip address for that machine and add it to Client.gd in the websocket_url (keep the `ws://` at the start). Once you've changed the websocket url and the survey url found in State.gd, you can export the project to html. Host the html files somewhere where they can be accessed by participants (e.g., using apache, nginx, etc.) as the game cannot be run locally from downloaded html files.