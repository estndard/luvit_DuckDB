from dash import Dash, dcc, html, Input, Output, callback, dash_table
import plotly.graph_objects as go
import plotly.express as px
from PIL import Image
import pandas as pd
import duckdb
con_espn = duckdb.connect("./espn.duckdb")

def scale_X(X_list):
    return [140 - (X * 140) for X in X_list]
def scale_Y(Y_list):
    return [(X * 100) for X in Y_list]

## 팀 정보 테이블 데이터 로드 및 정리
team_info = con_espn.sql("""
    WITH standing_table AS (
        FROM standings
            JOIN (
            FROM teamStats
            SELECT teamId, 
                avg(COLUMNS(* EXCLUDE (seasonType, eventId, teamId, teamOrder,
                    updateTime))).round(1)
            WHERE seasonType = 12654 and possessionPct is not null
            GROUP BY teamID) AS teamStats USING (teamId)
            JOIN teams USING (teamId)
            SELECT displayName, * EXCLUDE (seasonType, year, leagueId, 
                last_matchDateTime, deductions, form, next_opponent, 
                next_matchDateTime, next_homeAway, timeStamp, location, name, 
                abbreviation, displayName, shortDisplayName, color, alternateColor, 
                logoURL, venueId, slug)
            WHERE seasonType = 12654)
        FROM standing_table
        UNION ALL
        FROM standing_table
        SELECT 'All', null, avg(COLUMNS(* EXCLUDE (displayName, teamRank))).round(1)
""")

## 컬럼 이름 한글화
standing_table_1_col = ['팀명', '순위', '경기 수', '승', '무', '패', '승점', '득점', '실점', '골차', 
    '점유율', '파울', '옐로카드', '레드카드', '오프사이드', '코너킥', '세이브', '슈팅수', 
    '유효 슈팅수', '슛률']
standing_table_2_col = ['팀명', '페널티킥 득점', '페널티킥 슈팅', '정확한 패스', '패스 수', 
    '패스 성공률', '정확한 크로스', '크로스 수', '크로스 성공률', '롱볼 수', '정확한 롱볼', 
    '롱볼 성공률', '차단된 슈팅', '효과적인 태클', '태클 수', '태클 성공률', '가로채기', 
    '효과적인 클리어링', '클리어링 수']

## 주요 지표와 패스/크로스 지표로 나눠서 정리하고 열 이름 설정한 팬더스 데이터프레임 생성
standing_table_1_df = team_info.project('''displayName, teamRank, gamesPlayed, wins, ties, 
    losses, points, gf, ga, gd, possessionPct, foulsCommitted, yellowCards, redCards, offsides,
    wonCorners, saves, totalShots, shotsOnTarget, shotPct
    ''').df().set_axis(standing_table_1_col, axis=1)

standing_table_2_df = team_info.project('''displayName, penaltyKickGoals, penaltyKickShots, 
    accuratePasses, totalPasses, passPct, accurateCrosses, totalCrosses, crossPct, 
    totalLongBalls, accurateLongBalls, longballPct, blockedShots, effectiveTackles, totalTackles, 
    tacklePct, interceptions, effectiveClearance, totalClearance
    ''').df().set_axis(standing_table_2_col, axis=1)

goals_team = con_espn.sql("""
with base_table as (
    from keyEvents_2024_EPL
        join keyEventDescription using (keyEventTypeId)
        join teamroster using (athleteId)
        join fixtures using (eventId)
        join teams as away on (away.teamId = fixtures.awayTeamId)
        join teams as home on (home.teamId = fixtures.homeTeamId)
    select eventId, playId, playerDisplayName, keyEventName, 
    fieldPositionX, fieldPositionY, fieldPosition2X, fieldPosition2Y, 
    date.strftime('%Y년 %m월 %d일') as play_date, teamName,
    home.displayName as hometeam, away.displayName as awayteam
    where scoringPlay = 1 and participantOrder = 1 and 
        teamRoster.seasonType = 12654)
    from base_table
    select *, case when(hometeam != teamName) then hometeam
         else awayteam end as opposite order by play_date, teamName;""").df()
## 팀 목록 로드 + 'All' 추가
teamName = con_espn.query("""
    FROM teamRoster
    SELECT DISTINCT teamName
    WHERE seasonType = 12654
    ORDER BY teamName""").fetchnumpy()['teamName'].tolist() + ['All']
## 득점 이벤트 요약 정보
goal_info = goals_team.loc[:, ['playerDisplayName', 'keyEventName', 'play_date',
    'opposite']].rename(
        columns={'playerDisplayName': '선수명', 'keyEventName': '득점 종류', 
            'play_date': '경기 날짜', 'opposite': '상대팀'})

## 득점 지도용 설정
## 골 타입별 색상 매핑
color_map = {"Penalty - Scored": "red", "Goal - Header": "lightblue",
    "Goal - Free-kick": "black", "Goal": "whitesmoke"}

## 골 지도에 사용할 경기장 배경 및 기타 레이아웃 설정
layout = {
    "images": [dict(source=Image.open('./half_stadium.png'),
        xref="x", yref="y", x=-10, y=130, sizex=160, sizey=140, 
        sizing="stretch", layer="below")],
    "xaxis": dict(range=[-10, 160], showgrid=False, zeroline=False, showticklabels=False,
        title=None),
    "yaxis": dict(range=[-10, 130], showgrid=False, zeroline=False, showticklabels=False,
        title=None),
    "plot_bgcolor": 'white', "height": 600, "width": 900,
    "legend": dict(title=dict(text='골 타입'), bgcolor='green', font=dict(color='white'))}
## 마우스 오버 시 보여줄 템플릿
hovertemplate = {"hovertemplate":
    "<b>%{customdata[0]}</b><br><br><b>상대팀:%{customdata[1]}</b><br>" +
    "<b>경기일:%{customdata[2]}</b><br><b>득점자:%{customdata[3]}</b><br><br><extra></extra>",
    "mode": 'markers'}
## 초기 골 지도 그래프 생성
fig = px.scatter(goals_team, x=scale_X(goals_team['fieldPositionY']), 
    y=scale_Y(goals_team['fieldPositionX']), color='keyEventName', 
    color_discrete_map=color_map,
    custom_data=["teamName", "opposite", 'play_date', 'playerDisplayName'])

## Dash 애플리케이션 인스턴스 생성
app = Dash()
server = app.server

## 대시보드 레이아웃 정의
app.layout = html.Div(
    style={"display": "flex", "flexDirection": "column", "alignItems": "center", "width": "100%", 
        "fontFamily": "NanumGothic"},
    children=[html.H1('EPL 데이터 분석', style={"textAlign": "center", "width": "100%"}),
        html.Div('DuckDB를 사용한 ESPN EPL 데이터 분석: 2024/25 프리미어리그', 
            style={"textAlign": "center", "marginBottom": "30px"}),
        html.Div(children=[
            html.H2('팀 선택'),
            dcc.Dropdown(teamName, 'All', id='Team_select', style={'width': '300px'})], 
        style={"display": "flex", "flexDirection": "column", "alignItems": "center", 
            "marginBottom": "30px", "width": "100%"}),
        html.Div(children=[
            html.H2('팀 결과'),
            dash_table.DataTable(id='team_info-table1', 
                data=standing_table_1_df[standing_table_1_df['팀명'] == 'ALL'].to_dict('records'),
                page_size=13, style_cell={'textAlign': 'center', 'padding': '5px', 'width': '80px'}),
            html.H2('공격 효율(경기당 평균)'),
            dash_table.DataTable(id='team_info-table2', 
                data=standing_table_2_df[standing_table_2_df['팀명'] == 'ALL'].to_dict('records'),
                page_size=13, 
                style_cell={'textAlign': 'center', 'padding': '5px', 'width': '80px'})], 
                style={"display": "flex", "flexDirection": "column", "alignItems": "center",
                    "marginBottom": "30px", "width": "100%"}),
            html.Div(children=[
                html.Div(children=[
                    html.H3("득점 정보 테이블",
                        style={"textAlign": "center", "marginBottom": "20px"}),
                    dash_table.DataTable(id='team_goal-table', data=goal_info.to_dict('records'),
                        page_size=13, page_current=0, 
                        style_cell={'textAlign': 'center', 'padding': '10px'})], 
                style={"flex": "0.8", "display": "flex", "flexDirection": "column", 
                    "alignItems": "center", "height": "100%", "overflow": "auto"}),
                html.Div(children=[
                    html.H3("팀별 득점 지도", 
                        style={"textAlign": "center", "marginBottom": "20px"}),
                    dcc.Graph(id='team_goal-map', figure=fig)], 
                        style={"flex": "1.2", "display": "flex", "flexDirection": "column",
                            "alignItems": "center", "height": "100%", "overflow": "auto"})], 
                    style={"display": "flex", "alignItems": "flex-start", "justifyContent": "center",
                        "width": "90%", "height": "100%", "overflow": "auto"})
    ]
)

## 콜백: 드롭다운 선택과 득점 테이블 클릭에 따른 업데이트
@callback(
    Output('team_goal-map', 'figure'), Output('team_goal-table', 'data'), 
    Output('team_info-table1', 'data'), Output('team_info-table2', 'data'),
    Input('Team_select', 'value'), Input('team_goal-table', 'active_cell'), 
    Input('team_goal-table', 'data'), Input('team_goal-table', 'page_current'), 
    Input('team_goal-table', 'page_size'))
def update_table_and_figure(Team_select, active_cell, table_data, page_current, page_size):
# 팀 선택 처리
    if Team_select == 'All':
        goals_team_selected = goals_team.copy()
    else:
        goals_team_selected = goals_team[goals_team['teamName'] == Team_select]
# 득점 지도 업데이트
    fig = px.scatter(goals_team_selected, 
        x=scale_X(goals_team_selected['fieldPositionY']),
        y=scale_Y(goals_team_selected['fieldPositionX']),
        color='keyEventName', color_discrete_map=color_map,
        custom_data=["teamName", "opposite", 'play_date', 'playerDisplayName'])

    fig.update_traces(**hovertemplate)
    fig.update_layout(**layout)
# 클릭한 득점 위치를 강조 표시
    if active_cell:
        row_in_page = active_cell['row']
        real_row = page_current * page_size + row_in_page
        if real_row < len(goals_team_selected):
            clicked_data = goals_team_selected.iloc[real_row]
            subset = goals_team[(goals_team['playerDisplayName'] ==
                clicked_data['playerDisplayName']) & 
                (goals_team['play_date'] == clicked_data['play_date'])]
            if not subset.empty:
                position_x = subset['fieldPositionX'].values[0]
                position_y = subset['fieldPositionY'].values[0]
                fig.add_trace(
                    go.Scatter(x=scale_X([position_y]), y=scale_Y([position_x]),
                        mode='markers', name='클릭 포인트',
                        marker=dict(size=12, symbol='star', color='red')))
# 업데이트할 데이터 테이블 반환
    update_goals_team_selected = (
        goals_team_selected.loc[:, ['playerDisplayName', 'keyEventName', 
            'play_date', 'opposite']]
            .rename(columns={'playerDisplayName': '선수명', 
                'keyEventName': '득점 종류', 'play_date': '경기 날짜', 
                'opposite': '상대팀'}).to_dict('records'))
    update_standing_team_selected1 = (
        standing_table_1_df[standing_table_1_df['팀명'] == Team_select].to_dict('records'))
    update_standing_team_selected2 = (
        standing_table_2_df[standing_table_2_df['팀명'] == Team_select].to_dict('records'))
    return (fig, update_goals_team_selected, update_standing_team_selected1, 
        update_standing_team_selected2)


## P336
if __name__ == '__main__':
    app.run(debug=False, jupyter_mode='external')
