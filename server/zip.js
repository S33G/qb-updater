const extract = require('extract-zip')
const fetch = require('node-fetch')

on('qb-updater:unzip', (input, output) => {
    console.log(`Unzipping ${input} to ${output}`)

    extract(input, {
        dir: output,

    }).then(() => {
        console.log('Extraction complete')
    }).catch((err) => {
        return console.error('Extraction error: ' + err)
    })
    
    fetch(`https://qb-updater/extraction-complete`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            success: true,
            output: output,
        })
    })
})