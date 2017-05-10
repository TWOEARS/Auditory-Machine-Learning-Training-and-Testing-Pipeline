import freesound
import os


def getFreesoundData(freesoundToken, dir, maxCount = -1, query='', tags='', duration='', sort=''):
    client = freesound.FreesoundClient()
    client.client_id = id;
    client.set_token(freesoundToken)

    print("FreesoundDownloader: ---------- GET SOUND DATA")
    results_pager = client.text_search(
        query=query,
        filter=tags + ' ' + duration,
        sort=sort ,
        fields="id,name,previews"
    )

    index = 1
    limit =  results_pager.count if maxCount < 0 else min(maxCount, results_pager.count)
    while index <= limit:
        for sound in results_pager:
            if getSound(sound, dir):
                index += 1
            # stop loop if limit of sounds is reached
            if index > limit:
                break

        # load next page
        results_pager = results_pager.next_page()
        # stop loop if next page has no objects
        if  results_pager is None:
            break
        print
    print "FreesoundDownloader: ---------- STORED", index - 1,"SOUNDS"
    print "FreesoundDownloader: ---------- FINISHED"

def getSound(sound, dir):
    if not isinstance(sound, freesound.Sound):
        print "FreesoundDownloader: <sound> is no valid object of class Freesound.Sound"
        return False

    if not os.path.isdir(dir):
        print "FreesoundDownloader: directory ", dir, " does not exist!"
        return False

    fileName = sound.previews.preview_hq_mp3.split("/")[-1]
    if os.path.isfile(os.path.join( dir, fileName)):
        print "FreesoundDownloader: sound file <", fileName, "> has been found in data base"
    else:
        print "FreesoundDownloader: download sound file ", fileName, "..."
        sound.retrieve_preview(dir)
    return True

#getFreesoundData('JD5yoY90BEYZ4h7w99o7sgYkMiAHkdmGoYCvJQpz', './fun', 40, '', 'tag:cat', 'duration:[0 TO 20]', 'downloads_desc')