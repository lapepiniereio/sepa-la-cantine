import { useState } from 'react'
import { Button } from './components/button'
import { Input } from './components/input'

function App(): JSX.Element {
  const [filePaths, setFilePaths] = useState<string[]>([])

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (!files) return
    setFilePaths(Array.from(files).map((x) => x.path))
  }

  const handleProcessFiles = () => {
    ;(window as any).api.processFiles(filePaths).then((result: 'ok') => {
      console.log(result)
    })
  }

  return (
    <div className="min-h-screen bg-gray-100 p-4">
      <h1 className="text-4xl font-bold">Selectionner les fichiers à traiter</h1>
      <Input type="file" multiple={true} onChange={handleFileChange} />
      <Button className="mt-4" onClick={handleProcessFiles}>
        Modifier
      </Button>
    </div>
  )
}

export default App
