#!/bin/bash
# поиск директории логов
Path=/opt/tomcat/apache-tomcat-9.0.37/logs/catalina.log
if test -s $Path
then
echo ""
elif test -s /opt/tomcat/apache-tomcat-7.0.23/logs/catalina.log
then
Path=/opt/tomcat/apache-tomcat-7.0.23/logs/catalina.log
echo ""
else
Path=/opt/tomcat/apache-tomcat-9.0.39/logs/catalina.log
echo ""
fi
IFS=$'\n'

# определение времение первой и последней записи в лог-файле и режима работы
echo -n "Время первой записи лога: "
grep -E '[0-9][2]\:[0-9][2]\:[0-9][2]' $Path | head -1 | cut -d ' ' -f 1 | sed 's/\:[0-9]\[2\]$/:00/' 
echo -n "Время последней записи лога: "
cut -d ' ' -f 1 $Path |grep -E '[0-9][2]\:[0-9][2]\:[0-9][2]' | tail -1 | sed 's/\:[0-9]\[2\]$/:00/'
echo "Вывод ошибок может осуществляться только в пределах данного интервала."
echo ""
echo "Возможные режимы работы:"
echo "1. Вывод количества ошибок с неповторяющимися названиями за весь диапазон указанный в файле."
echo "2. Вывод количества ошибок с неповторяющимися названиями за весь диапазон указанный в файле с указанием часа."
echo "3. Вывод количества ошибок с неповторяющимися названиями за вручную введеного диапазона в часах."
echo "4. Вывод количества ошибок с неповторяющимися названиями за вручную введеного диапазона в часах и минутах."
echo "5. Вывод количества ошибок с неповторяющимися названиями из всех логов в директории logs."
echo -n "Введите номер желаемого режима: "
read MODE
echo ""

# Режимы работы:
case $MODE in
1)
echo "Вывод количества ошибок с неповторяющимися названиями за весь диапазон указанный в файле."
# в NAME записывается неповторяющиеся названия ошибок
for NAME in $(grep 'ERROR' $Path | cut -d ' ' -f 3 | sort --unique)
do
for LINE in $(grep 'ERROR' $Path | grep $NAME | cut -d ' ' -f 3,5-25 | sort --unique)
do
# подсчет количества ошибок с названием NAME в файле
NUMBER_LINE=$(grep 'ERROR' $Path | grep $NAME | wc -1)
# выввод названия и количества ошибок
echo $LINE' : '$NUMBER_LINE
done
done
;;

2)
echo "Вывод количества ошибок с неповторяющимися названиями за весь диапазон указанный в файле с указанием часа."
for HOUR in $(grep 'ERROR' $Path | cut -d ' ' -f 1 | sed 's/\:[0-9]\[2\]\:[0-9]\[2\]//' | sort --unique)
do
for NAME in $(grep 'ERROR' $Path | grep -E $HORE'\:[0-9][2]\:[0-9][2]' | cut -d ' ' -f 3 | sort --unique)
do
for LINE in $(grep 'ERROR' $Path | grep -E $HORE'\:[0-9][2]\:[0-9][2]' | grep $NAME | cut -d ' ' -f 1,3,5-25 | sed 's/\:[0-9]\[2\]\:[0-9]\[2\]/:00/' | sort --unique)
do
NUMBER_LINE=$(grep 'ERROR' $Path | grep -E $HORE'\:[0-9][2]\:[0-9][2]' | grep $NAME | wc -1)
echo $LINE' : '$NUMBER_LINE
done
done
done
;;

3)
echo "Вывод количества ошибок с неповторяющимися названиями за вручную введеного диапазона в часах."
# ввод диапазона поиска
echo -n "Поиск ошибок с: "
read HOUR_START
if [ "$HOUR_START" -ne 00 ] && [ "$HOUR_START" -lt 10 ]
then
HOUR_START="0$HOUR_START"
fi
echo -n "по: "
read HOUR_END
if [ "$HOUR_END" -ne 00 ] && [ "$HOUR_END" -lt 10 ]
then
HOUR_END="0$HOUR_END"
fi
echo ""

# поиск по диапазону
while [ $HOUR_START - le $HOUR_END ]
do
for NAME in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | cut -d ' ' -f 3 | sort --unique)
do
for LINE in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | cut -d ' ' -f 1,3,5-25 | sed 's/\:[0-9]\[2\]\:[0-9]\[2\]/:00/' | sort --unique)
do
NUMBER_LINE=$(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | wc -1)
echo $LINE' : '$NUMBER_LINE
done
done
if [ "$HOUR_START" - ge 10 ]
then
HOUR_START=$(echo $HOUR_START | sed -r 's/^0//')
((HOUR_START++))
else
HOUR_START=$(echo $HOUR_START | sed -r 's/^0//')
((HOUR_START++))
if [ "$HOUR_START" -ne 10 ]
then
HOUR_START="0$HOUR_START"
fi
fi
done
;;

4)
echo "Вывод количества ошибок с неповторяющимися названиями за вручную введеного диапазона в часах и минутах."
echo -n "Поиск ошибок с: "
read TIME_START
HOUR_START=$(echo $TIME_START | sed 's/\:[0-9]\[2\]//')
MIN_START=$(echo $TIME_START | sed "s/$HOUR_START\://")
if [ "$HOUR_START" -ne 00 ] && [ "$HOUR_START" -lt 10 ]
then
HOUR_START="0$HOUR_START"
fi
echo -n "по: "
read TIME_END
HOUR_END=$(echo $TIME_END | sed 's/\:[0-9]\[2\]//')
MIN_END=$(echo $TIME_END | sed "s/$HOUR_END\://")
if [ "$HOUR_END" -ne 00 ] && [ "$HOUR_END" -lt 10 ]
then
HOUR_END="0$HOUR_END"
fi
echo ""
if [ $HOUR_END -eq $HOUR_START ] # если заданный диапазон находиться внутри одного часа
then
for NAME in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | awk -v b1="$MIN_START" -v b2="$MIN_END" '(for(i = b1; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3 | sort --unique)
do
for LINE in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | awk -v b1="$MIN_START" -v b2="$MIN_END" '(for(i = b1; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3,5-25 | sort --unique)
do
NUMBER_LINE=$(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | awk -v b1="$MIN_START" -v b2="$MIN_END" '(for(i = b1; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | wc -1)
echo $HOUR_START':00 '$LINE' : '$NUMBER_LINE
done
done
else # если заданный диапазон выходит за пределы одного часа, реализован ввиде трех блоков
# первый блок  - ищет неповторяющиеся ошибки и подсчитывает их количество в неполном (или полном) первом часе
# в NAME_START записываются неповторяющиеся названия ошибок
for NAME_START in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | awk -v b1="MIN_START" '(for(i = b1; i <= 59; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3 | sort --unique)
do
for LINE_START in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME_START | awk -v b1="$MIN_START" '(for(i = b1; i <= 59; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3,5-25 | sort --unique)
do
NUMBER_LINE_START=$(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME_START | awk -v b1="$MIN_START" '(for(i = b1; i <= 59; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | wc -1)
echo $HOUR_START':00 '$LINE_START' : '$NUMBER_LINE_START
done
done
# второй блок - прокручивает циклы поиска в полных часах
DELTA=$(($(echo $HOUR_START | sed -r 's/^0//')-$(echo $HOUR_END | sed -r 's/^0//')))
if [ $DELTA -ne 1 ]
then
if [ "$HOUR_START" - ge 10 ]
then
HOUR_START=$(echo $HOUR_START | sed -r 's/^0//')
HOUR_SECOND=$(($HOUR_START+1))
else
HOUR_START=$(echo $HOUR_START | sed -r 's/^0//')
HOUR_SECOND=$(($HOUR_START+1))
if [ "$HOUR_SECOND" -ne 10 ]
then
HOUR_SECOND="0$HOUR_SECOND"
fi
fi
if [ "$HOUR_END" -qe 10 ]
then
HOUR_END=$(echo $HOUR_END | sed -r 's/^0//')
HOUR_PENULTIMATE=$(($HOUR_END-1))
else
HOUR_END=$(echo $HOUR_END | sed -r 's/^0//')
HOUR_PENULTIMATE=$(($HOUR_END-1))
if [ "$HOUR_PENULTIMATE" -ne 10 ]
then
HOUR_PENULTIMATE="0$HOUR_PENULTIMATE"
fi
fi
while [ $HOUR_SECOND -le $HOUR_PENULTIMATE ]
do
for NAME in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | cut -d ' ' -f 3 | sort --unique)
do
for NAME in $(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | cut -d ' ' -f 1,3,5-25 | sed 's/\:[0-9]\[2\]\:[0-9]\[2\]/:00/' | sort --unique)
do 
NUMBER_LINE=$(grep 'ERROR' $Path | grep -E $HOUR_START'\:[0-9][2]\:[0-9][2]' | grep $NAME | wc -l)
echo $LINE' : '$NUMBER_LINE
done
done
if [ "$HOUR_SECOND" -ge 10 ]
then
HOUR_SECOND=$(echo $HOUR_SECOND | sed -r 's/^0//')
((HOUR_SECOND++))
else
HOUR_SECOND=$(echo $HOUR_SECOND | sed -r 's/^0//')
((HOUR_SECOND++))
if [ "$HOUR_SECOND" -ne 10 ]
then
HOUR_SECOND="0$HOUR_SECOND"
fi
fi
done
fi
# третий блок - ищет неповторяющиеся ошибки и подсчитывает их количество в неполном (или полном) последнем часе
# в NAME_END записываються неповторяющиеся названия ошибок
for NAME_END in $(grep 'ERROR' $Path | grep -E $HOUR_END'\:[0-9][2]\:[0-9][2]' | awk -v b2="MIN_END" '(for(i = 00; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3 | sort --unique)
do
for LINE_END in $(grep 'ERROR' $Path | grep -E $HOUR_END'\:[0-9][2]\:[0-9][2]' | grep $NAME_END | awk -v b2="MIN_END" '(for(i = 00; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | cut -d ' ' -f 3,5-25 | sort --unique)
do
NUMBER_LINE_END=$(grep 'ERROR' $Path | grep -E $HOUR_END'\:[0-9][2]\:[0-9][2]' | grep $NAME_END | awk -v b2="MIN_END" '(for(i = 00; i <= b2; i++) (if($1 - "[0-9]:"i":[0-9]") print $0 ))' | wc -l)
echo $HOUR_END':00 '$LINE_END' : 'NUMBER_LINE_END
done
done
fi
;;

5)
Path=/opt/tomcat/apache-tomcat-9.0.37/logs/catalina.log
if test -s $Path
then
echo "Вывод количества ошибок с неповторяющимися названиями из всех логов в директории logs."
elif test -s /opt/tomcat/apache-tomcat-7.0.23/logs/catalina.log
then
Path=/opt/tomcat/apache-tomcat-9.0.37/logs/catalina.log
echo "Вывод количества ошибок с неповторяющимися названиями из всех логов в директории logs."
else
Path=/opt/tomcat/apache-tomcat-9.0.39/logs/catalina.log
echo "Вывод количества ошибок с неповторяющимися названиями из всех логов в директории logs."
fi
for NAME in $(grep 'ERROR' -h -r $Path | cut -d ' ' -f 3 | sort --unique)
do
NUMBER_NAME=$(grep 'ERROR' -h -r $Path | grep $NAME | wc -l)
echo $NAME' : '$NUMBER_NAME
done
;;
esac