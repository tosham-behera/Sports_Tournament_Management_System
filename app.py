from flask import Flask, render_template, request, redirect
import mysql.connector
from datetime import date

app = Flask(__name__, template_folder='static')

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="NOOB",
        database="sports_tournament"
    )

@app.route("/")
def index():
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT * FROM Sports")
    sports = cursor.fetchall()

    selected_sport_id = request.args.get("sport_id", sports[0]["sport_id"] if sports else None)
    selected_sport_id = int(selected_sport_id)
    selected_sport_name = next((s["sport_name"] for s in sports if s["sport_id"] == selected_sport_id), "")

    cursor.execute("""
        SELECT
            m.match_id,
            m.match_date,
            s.sport_name,
            v.venue_name,
            r.referee_name,
            t1.team_name  AS team1_name,
            t2.team_name  AS team2_name,
            m.team1_score,
            m.team2_score,
            CASE
                WHEN m.team1_score > m.team2_score THEN t1.team_name
                WHEN m.team2_score > m.team1_score THEN t2.team_name
                ELSE 'Draw'
            END AS winner
        FROM Matches m
        JOIN Sports   s  ON m.sport_id   = s.sport_id
        JOIN Venues   v  ON m.venue_id   = v.venue_id
        JOIN Referees r  ON m.referee_id = r.referee_id
        JOIN Teams    t1 ON m.team1_id   = t1.team_id
        JOIN Teams    t2 ON m.team2_id   = t2.team_id
        WHERE m.sport_id = %s
        ORDER BY m.match_date DESC
    """, (selected_sport_id,))
    matches = cursor.fetchall()

    cursor.execute("SELECT * FROM Tournament_Standings WHERE sport_name = %s", (selected_sport_name,))
    standings = cursor.fetchall()

    cursor.execute("""
        SELECT t.team_id, t.team_name, t.total_wins, t.total_losses, s.sport_name
        FROM Teams t JOIN Sports s ON t.sport_id = s.sport_id
        WHERE t.sport_id = %s
    """, (selected_sport_id,))
    teams = cursor.fetchall()

    cursor.execute("""
        SELECT r.referee_id, r.referee_name, s.sport_name, s.sport_id
        FROM Referees r JOIN Sports s ON r.sport_id = s.sport_id
        WHERE r.sport_id = %s
    """, (selected_sport_id,))
    referees = cursor.fetchall()

    cursor.execute("""
        SELECT p.player_id, p.player_name, p.age, p.position, t.team_name, s.sport_name
        FROM Players p
        JOIN Teams  t ON p.team_id  = t.team_id
        JOIN Sports s ON t.sport_id = s.sport_id
        WHERE t.sport_id = %s
    """, (selected_sport_id,))
    players = cursor.fetchall()

    cursor.execute("SELECT * FROM Venues")
    venues = cursor.fetchall()

    cursor.close()
    db.close()

    today = date.today().isoformat()

    return render_template("index.html",
        sports=sports,
        selected_sport_id=selected_sport_id,
        selected_sport_name=selected_sport_name,
        matches=matches,
        standings=standings,
        teams=teams,
        referees=referees,
        players=players,
        venues=venues,
        today=today,
        message=request.args.get("message", None),
        error=request.args.get("error", None)
    )

@app.route("/add-team", methods=["POST"])
def add_team():
    team_name = request.form["team_name"]
    sport_id  = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO Teams (team_name, sport_id) VALUES (%s, %s)", (team_name, sport_id))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Team+added+successfully")

@app.route("/delete-team", methods=["POST"])
def delete_team():
    team_id  = request.form["team_id"]
    sport_id = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM Teams WHERE team_id = %s", (team_id,))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Team+deleted")

@app.route("/add-player", methods=["POST"])
def add_player():
    player_name = request.form["player_name"]
    age         = request.form["age"]
    position    = request.form["position"]
    team_id     = request.form["team_id"]
    sport_id    = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO Players (player_name, age, position, team_id) VALUES (%s, %s, %s, %s)",
        (player_name, age, position, team_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Player+added+successfully")

@app.route("/delete-player", methods=["POST"])
def delete_player():
    player_id = request.form["player_id"]
    sport_id  = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM Players WHERE player_id = %s", (player_id,))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Player+deleted")

@app.route("/add-referee", methods=["POST"])
def add_referee():
    referee_name = request.form["referee_name"]
    sport_id     = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO Referees (referee_name, sport_id) VALUES (%s, %s)", (referee_name, sport_id))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Referee+added+successfully")

@app.route("/delete-referee", methods=["POST"])
def delete_referee():
    referee_id = request.form["referee_id"]
    sport_id   = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM Referees WHERE referee_id = %s", (referee_id,))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Referee+deleted")

@app.route("/add-match", methods=["POST"])
def add_match():
    sport_id    = request.form["sport_id"]
    venue_id    = request.form["venue_id"]
    referee_id  = request.form["referee_id"]
    team1_id    = request.form["team1_id"]
    team2_id    = request.form["team2_id"]
    team1_score = request.form["team1_score"]
    team2_score = request.form["team2_score"]
    match_date  = request.form["match_date"]

    if date.fromisoformat(match_date) < date.today():
        return redirect(f"/?sport_id={sport_id}&error=Match+date+cannot+be+in+the+past!")

    if team1_id == team2_id:
        return redirect(f"/?sport_id={sport_id}&error=Team+1+and+Team+2+cannot+be+the+same!")

    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT sport_id FROM Teams WHERE team_id = %s", (team1_id,))
    t1 = cursor.fetchone()
    cursor.execute("SELECT sport_id FROM Teams WHERE team_id = %s", (team2_id,))
    t2 = cursor.fetchone()

    if t1["sport_id"] != t2["sport_id"]:
        cursor.close(); db.close()
        return redirect(f"/?sport_id={sport_id}&error=Both+teams+must+belong+to+the+same+sport!")

    cursor.execute("SELECT sport_id FROM Referees WHERE referee_id = %s", (referee_id,))
    ref = cursor.fetchone()
    if ref["sport_id"] != t1["sport_id"]:
        cursor.close(); db.close()
        return redirect(f"/?sport_id={sport_id}&error=Referee+must+belong+to+the+same+sport+as+the+teams!")

    cursor.execute(
        """INSERT INTO Matches
           (sport_id, venue_id, referee_id, team1_id, team2_id, team1_score, team2_score, match_date)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
        (sport_id, venue_id, referee_id, team1_id, team2_id, team1_score, team2_score, match_date)
    )
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Match+scheduled!+Trigger+auto-updated+wins+and+losses")

@app.route("/delete-match", methods=["POST"])
def delete_match():
    match_id = request.form["match_id"]
    sport_id = request.form["sport_id"]
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM Matches WHERE match_id = %s", (match_id,))
    db.commit()
    cursor.close()
    db.close()
    return redirect(f"/?sport_id={sport_id}&message=Match+deleted")

if __name__ == "__main__":
    app.run(debug=True, port=3000)
